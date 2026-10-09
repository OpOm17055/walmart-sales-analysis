CREATE TABLE walmart (
  invoice_id INT,
  branch VARCHAR(10),
  city VARCHAR(50),
  category VARCHAR(50),
  unit_price NUMERIC(10,2),
  quantity INT,
  date DATE,
  time TIME,
  payment_method VARCHAR(20),
  rating NUMERIC(3,1),
  profit_margin NUMERIC(4,2),
  total NUMERIC(12,2),
  profit NUMERIC(12,4),
  year INT,
  month_name VARCHAR(12),
  day_name VARCHAR(12),
  hour INT,
  shift VARCHAR(12)
);


SELECT * FROM WALMART LIMIT 10;


-- 1. BUSINESS SNAPSHOT


-- 1.1 Headline KPIs
SELECT COUNT(*) AS transactions,
       ROUND(SUM(total), 0) AS revenue,
       ROUND(SUM(profit), 0) AS profit,
       ROUND(100 * SUM(profit) / SUM(total), 1) AS profit_margin_pct,
       ROUND(AVG(total), 2) AS avg_order_value,
       ROUND(AVG(quantity), 2) AS avg_items_per_order,
       ROUND(AVG(rating), 2) AS avg_rating
FROM walmart;
-- Result: 9,969 orders | revenue 1,209,726 | profit 476,139 | margin 39.4%
--         average order 121.35 | 2.36 items per order | average rating 5.83 out of 10
-- Insight: customer satisfaction is mediocre (5.83 out of 10), so ratings are the
--          main weakness to investigate in the sections below.




-- 2. PRODUCT ANALYSIS


-- 2.1 Category scorecard
SELECT category,
       COUNT(*) AS orders,
       SUM(quantity) AS units,
       ROUND(SUM(total), 0) AS revenue,
       ROUND(100 * SUM(total) / SUM(SUM(total)) OVER (), 1) AS revenue_pct,
       ROUND(100 * SUM(profit) / SUM(total), 1) AS margin_pct,
       ROUND(AVG(total), 2) AS avg_order_value,
       ROUND(AVG(quantity), 2) AS avg_items,
       ROUND(AVG(rating), 2) AS avg_rating
FROM walmart
GROUP BY category
ORDER BY revenue DESC;
-- Result: Fashion 40.5% | Home & Lifestyle 40.4% | Electronic 6.5% |
--         Food 4.4% | Sports 4.3% | Health & Beauty 3.9%
-- Insights:
--  1. Two categories (Fashion, Home & Lifestyle) make up 81% of revenue.
--  2. Margins are almost the same in every category (39-40%), so the category mix
--     affects revenue but not profitability.
--  3. Food, Sports and Health orders are about 3x bigger (average ~310 vs ~108,
--     about 5.5 items vs 2.1) and are rated much higher (~7.0 vs ~5.8).




-- 2.2 Revenue by unit-price band
SELECT CASE WHEN unit_price < 30 THEN '1. Under 30'
            WHEN unit_price < 60 THEN '2. 30 to 60'
            ELSE '3. 60 and above' END AS price_band,
       COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS orders_pct,
       ROUND(SUM(total), 0) AS revenue,
       ROUND(100 * SUM(total) / SUM(SUM(total)) OVER (), 1) AS revenue_pct,
       ROUND(AVG(quantity), 2) AS avg_items
FROM walmart
GROUP BY price_band
ORDER BY price_band;
-- Result: Under 30 = 21.1% of orders, 8.9% of revenue
--         30 to 60 = 41.1% of orders, 34.0% of revenue
--         60+      = 37.8% of orders, 57.1% of revenue
-- Insights:
--  1. Products priced 60 and above bring in 57% of revenue from 38% of orders, and
--     customers buy just as many of them per order (2.45 items vs 2.26-2.37).
--  2. Price is not holding back sales volume, so premium items deserve priority.






SELECT DISTINCT profit_margin
FROM walmart
ORDER BY profit_margin;

-- There are only 6 profit-margin slabs: 0.18, 0.21, 0.33, 0.36, 0.48 and 0.57.



-- 2.3 Profit contribution by margin tier
SELECT profit_margin,
       COUNT(*)                                                AS orders,
       ROUND(SUM(profit), 0)                                   AS profit,
       ROUND(100 * SUM(profit) / SUM(SUM(profit)) OVER (), 1)  AS profit_pct,
       ROUND(AVG(rating), 2)                                   AS avg_rating
FROM walmart
GROUP BY profit_margin
ORDER BY profit_margin;
-- Result: the 48% margin tier has 4,519 orders but earns 55.0% of all profit.
--         The 33% margin tier has 4,542 orders and earns 38.2% of profit.
-- Insight: margin is set per branch, not per product (95 of 100 branches use one margin).
--          49 branches run at a 48% margin and 41 at 33%. Both groups sell the same mix
--          with similar revenue, yet the 48% branches earn 1.44 times the profit.
--          Closing that gap is the biggest profit lever.







-- 3. TIME PATTERNS




-- 3.1 Average monthly revenue across full years (2020 to 2023)
SELECT EXTRACT(MONTH FROM date) AS month_no,
       month_name,
       ROUND(SUM(total) / 4, 0) AS avg_revenue_per_year,
       ROUND(100 * SUM(total) / SUM(SUM(total)) OVER (), 1)  AS pct_of_year
FROM walmart
WHERE year BETWEEN 2020 AND 2023
GROUP BY month_no, month_name
ORDER BY month_no;

-- Insight: November and December alone bring in 55% of a year's revenue, and
--          August to October run at about 2.5 times a normal month. Stock and
--          staffing should start ramping up in August.





-- 3.2 Hour-by-hour demand
SELECT hour,
       COUNT(*)  AS orders,
       ROUND(SUM(total), 0)  AS revenue
FROM walmart
GROUP BY hour
ORDER BY hour;
-- Result: from 6am to 2pm there are about 300-440 orders an hour; from 3pm to 8pm,
--         about 970-1,190 an hour. After 9pm, demand collapses (135, 126 and 3 orders).
-- Insight: the 3pm-9pm window handles 63.9% of all orders. Demand roughly triples
--          at 3pm, which makes it the right time for the shift change.





-- 3.3 Peak window share (3pm to 9pm)
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE hour BETWEEN 15 AND 20) / COUNT(*), 1)   AS orders_pct,
       ROUND(100 * SUM(total) FILTER (WHERE hour BETWEEN 15 AND 20) / SUM(total), 1) AS revenue_pct
FROM walmart;
-- Result: 63.9% of orders and 61.5% of revenue come in just 6 hours of an 18-hour day.





-- 3.4 Busiest and quietest day-and-shift slots

SELECT shift,
	   COUNT(*) AS ORDERS,
	    ROUND(SUM(total), 0) AS revenue
FROM walmart
GROUP BY shift
ORDER BY orders DESC;

-- Afternoon is the busiest shift and morning is the quietest.




SELECT day_name,
	   shift,
	   COUNT(*) AS orders,
	   ROUND(SUM(total), 0) AS revenue
FROM walmart
GROUP BY day_name, shift
ORDER BY orders DESC
LIMIT 5;
-- Result: Thursday afternoon (706 orders) is the busiest slot, followed by the
--         Wednesday (677), Tuesday (669), Sunday (666) and Saturday (652) afternoons.


SELECT day_name, shift, COUNT(*) AS orders
FROM walmart
GROUP BY day_name, shift
ORDER BY orders ASC
LIMIT 3;
-- Result: Monday morning (259 orders) is the quietest slot, followed by the
--         Wednesday (266) and Sunday (292) mornings.
-- Insight: the busiest slot gets about 2.7 times the orders of the quietest. Morning
--          promotions could pull some demand away from the afternoon rush.





-- 3.5 Weekend vs weekday
SELECT CASE WHEN day_name IN ('Saturday', 'Sunday') THEN 'Weekend' ELSE 'Weekday' END AS day_type,
       COUNT(*) AS orders,
       ROUND(AVG(total), 2) AS avg_order_value,
       ROUND(SUM(total) / COUNT(DISTINCT date), 0) AS revenue_per_day
FROM walmart
GROUP BY day_type;

-- Result: the average weekend order is 125.07 vs 119.86 on weekdays;
--         revenue per day is 866 vs 814.
-- Insight: weekend shoppers spend about 4% more per order, and Saturday has the
--          highest revenue of any day (185,624) despite having fewer orders than Tuesday.









-- 4. PAYMENTS





-- 4.1 Payment method scorecard
SELECT payment_method,
       COUNT(*)                                             AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS orders_pct,
       ROUND(100 * SUM(total) / SUM(SUM(total)) OVER (), 1) AS revenue_pct,
       ROUND(AVG(rating), 2)                                AS avg_rating
FROM walmart
GROUP BY payment_method
ORDER BY orders DESC;
-- Result: Credit card 42.7% of orders (rating 5.42)
--         E-wallet    38.9% of orders (rating 6.48)
--         Cash        18.4% of orders (rating 5.42)
-- Insight: e-wallet customers rate their experience about 1 point higher than
--          card or cash customers. A faster checkout may be part of the reason, so
--          encouraging e-wallet use is a low-cost way to improve satisfaction.







-- 4.2 Preferred payment method per branch
WITH ranked AS (
    SELECT branch,
           payment_method,
           RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT payment_method, COUNT(*) AS branches_where_top
FROM ranked
WHERE rnk = 1
GROUP BY payment_method
ORDER BY branches_where_top DESC;
-- Result: e-wallet is the top method in 75 branches, credit card in 23 and cash in 2.
-- Insight: credit card leads overall, yet e-wallet leads in 3 out of 4 branches,
--          so credit card use is concentrated in a few large branches.







-- 5. BRANCH PERFORMANCE






-- 5.1 Revenue concentration by branch quartile
WITH b AS (
    SELECT branch, SUM(total) AS revenue
    FROM walmart
    GROUP BY branch
),
q AS (
    SELECT branch, revenue, NTILE(4) OVER (ORDER BY revenue DESC) AS quartile
    FROM b
)
SELECT quartile,
       COUNT(*) AS branches,
       ROUND(SUM(revenue), 0)  AS revenue,
       ROUND(100 * SUM(revenue) / (SELECT SUM(revenue) FROM b), 1) AS revenue_pct,
       ROUND(MIN(revenue), 0) AS min_branch,
       ROUND(MAX(revenue), 0) AS max_branch
FROM q
GROUP BY quartile
ORDER BY quartile;
-- Result: the top 25 branches bring in 43.5% of revenue and the bottom 25 bring in 15.1%.
--         The best branch earns 25,688 vs 5,039 for the weakest (a 5.1x gap).
-- Insight: a quarter of the branches earn nearly half of the revenue.





-- 5.2 Busiest branches vs customer ratings

WITH b AS (
    SELECT branch,SUM(total) AS revenue, AVG(rating) AS avg_rat
    FROM walmart
    GROUP BY branch
),
q AS (
    SELECT branch,revenue, avg_rat, NTILE(4) OVER (ORDER BY avg_rat DESC) AS quartile
    FROM b
)
SELECT quartile,
       COUNT(*) AS branches,ROUND(SUM(revenue), 0)  AS revenue,
       ROUND(100 * SUM(revenue) / (SELECT SUM(revenue) FROM b), 1) AS revenue_pct,
       ROUND(avg(avg_rat), 2)  AS avg_rat,
       ROUND(MIN(avg_rat), 2) AS min_branch,
       ROUND(MAX(avg_rat), 2) AS max_branch
FROM q
GROUP BY quartile
ORDER BY quartile;
-- Result: quartiles 1-3 (highest-rated branches, average rating 6.17 to 6.58) each bring in
--         about 19% of revenue. Quartile 4 (lowest-rated, 4.99 to 5.40) brings in 43.5%.
--         The 25 lowest-rated branches bring in 43.5% of all revenue, more than twice the
--         share of any other quartile. They are exactly the 25 highest-revenue branches from E1.
-- Insight (strongest finding): the higher a branch's sales, the lower its rating.
--          The busiest branches look overloaded, so adding staff or checkout
--          capacity there would protect the branches that earn the most.








-- 5.3 Lowest- and highest-rated branches
SELECT branch, city, COUNT(*) AS orders,
       ROUND(AVG(rating), 2)  AS avg_rating,
       ROUND(100.0 * COUNT(*) FILTER (WHERE rating < 5) / COUNT(*), 1) AS low_rating_pct
FROM walmart
GROUP BY branch, city
ORDER BY avg_rating ASC
LIMIT 5;
-- Result: WALM056 Rowlett 4.99 (43.8% of ratings below 5), WALM065 Texas City 5.04,
--         WALM054 Sherman 5.06, WALM075 San Marcos 5.08, WALM099 Weatherford 5.08.
--         All five handle 165-188 orders, which is among the highest volumes.

SELECT branch, city, COUNT(*) AS orders, ROUND(AVG(rating), 2) AS avg_rating
FROM walmart
GROUP BY branch, city
ORDER BY avg_rating DESC
LIMIT 5;
-- Result: WALM004 Austin 7.00, WALM076 Huntsville 6.81, WALM059 Pflugerville 6.73.
--         These branches handle only 56-79 orders, which supports the overload finding in E2.







-- 5.4 Branch growth, 2022 vs 2023
WITH r AS (
    SELECT branch,
           SUM(total) FILTER (WHERE year = 2022) AS rev_2022,
           SUM(total) FILTER (WHERE year = 2023) AS rev_2023
    FROM walmart
    GROUP BY branch
),
g AS (
    SELECT branch, 100 * (rev_2023 - rev_2022) / rev_2022 AS growth_pct
    FROM r
)
SELECT CASE WHEN growth_pct <= -25 THEN '1. Fell more than 25%'
            WHEN growth_pct < 0    THEN '2. Fell 0-25%'
            WHEN growth_pct < 25   THEN '3. Grew 0-25%'
            ELSE                        '4. Grew more than 25%' END AS growth_band,
       COUNT(*) AS branches
FROM g
GROUP BY growth_band
ORDER BY growth_band;
-- Result: 18 fell more than 25% | 24 fell 0-25% | 22 grew 0-25% | 36 grew more than 25%
-- Insight: total revenue grew 6.8% (from 217,405 to 232,260), but branch results are
--          polarized: 42 branches shrank while 36 grew by more than a quarter.






-- 5.5 Fastest-growing branches (2022 to 2023)
WITH r AS (
    SELECT branch, city,
           SUM(total) FILTER (WHERE year = 2022) AS rev_2022,
           SUM(total) FILTER (WHERE year = 2023) AS rev_2023
    FROM walmart
    GROUP BY branch, city
)
SELECT branch, city,
       ROUND(rev_2022, 0) AS rev_2022,
       ROUND(rev_2023, 0) AS rev_2023,
       ROUND(100 * (rev_2023 - rev_2022) / rev_2022, 1) AS growth_pct
FROM r
ORDER BY growth_pct DESC
LIMIT 5;
-- Result: WALM006 El Paso +172.9%, WALM010 Laredo +161.6%, WALM091 Little Elm +148.9%,
--         WALM072 Lancaster +120.1%, WALM077 Coppell +118.6%
-- Insight: study what these branches changed and apply it to the declining ones.





-- 5.6 Fastest-declining branches (2022 to 2023)
WITH r AS (
    SELECT branch, city,
           SUM(total) FILTER (WHERE year = 2022) AS rev_2022,
           SUM(total) FILTER (WHERE year = 2023) AS rev_2023
    FROM walmart
    GROUP BY branch, city
)
SELECT branch, city,
       ROUND(rev_2022, 0) AS rev_2022,
       ROUND(rev_2023, 0) AS rev_2023,
       ROUND(100 * (rev_2023 - rev_2022) / rev_2022, 1) AS growth_pct
FROM r
ORDER BY growth_pct asc
LIMIT 5;
-- Result: WALM045 Missouri City -62.6%, WALM047 Flower Mound -58.6%, WALM098 Mineral Wells -57.9%,
--         WALM033 Pearland -55.6%, WALM081 Friendswood -50.7%
-- Insight: these five branches lost more than half their revenue and need a root-cause review.







-- 6. CUSTOMER SATISFACTION



 
-- 6.1 Rating bands and spend
SELECT CASE WHEN rating < 5 THEN '1. Low (below 5)'
            WHEN rating < 7 THEN '2. Medium (5 to 7)'
            ELSE                 '3. High (7+)' END                AS rating_band,
       COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS orders_pct,
       ROUND(AVG(total), 2) AS avg_order_value
FROM walmart
GROUP BY rating_band
ORDER BY rating_band;
-- Result: Low 27.6% of orders (average 114.79) | Medium 37.0% (118.48) | High 35.4% (129.44)
-- Insight: more than 1 in 4 orders gets a rating below 5, and happy customers spend
--          about 13% more per order than unhappy ones.





-- 6.2 Share of low ratings by category
SELECT category,
       ROUND(100.0 * COUNT(*) FILTER (WHERE rating < 5) / COUNT(*), 1) AS low_rating_pct
FROM walmart
GROUP BY category
ORDER BY low_rating_pct DESC;
-- Result: Home & Lifestyle 29.3% | Fashion 27.4% | Electronic 27.0% | Health 15.8% | Food 13.8% | Sports 12.7%
-- Insight: the two biggest categories also have the highest share of unhappy
--          customers, so improving them protects 81% of revenue.

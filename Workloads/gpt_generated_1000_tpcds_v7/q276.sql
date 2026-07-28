/*
Goal: Analyse combined catalog, web and store‑return performance for the year 2001, for promotions sent via e‑mail, and for customers born on day 14 of the month. The query joins all twelve selected TPC‑DS tables, applies three selective filters, aggregates sales, returns and order counts by date, product category, brand and promotion, and also surfaces the catalog page department.
*/
WITH
date_filt AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq,
           d_day_name
    FROM   date_dim
    WHERE  d_year = 2001
),
promo_filt AS (
    SELECT p_promo_sk,
           p_promo_name
    FROM   promotion
    WHERE  p_channel_email = 'Y'
),
cust_filt AS (
    SELECT c_customer_sk
    FROM   customer
    WHERE  c_birth_day = 14
),
cat_sales_agg AS (
    SELECT cs.cs_sold_date_sk          AS date_sk,
           cs.cs_item_sk               AS item_sk,
           cs.cs_promo_sk              AS promo_sk,
           cs.cs_catalog_page_sk       AS page_sk,
           SUM(cs.cs_ext_sales_price)  AS catalog_sales,
           COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM   catalog_sales cs
    JOIN   cust_filt c      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN   promo_filt p     ON cs.cs_promo_sk = p.p_promo_sk
    JOIN   date_filt d      ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk, cs.cs_promo_sk, cs.cs_catalog_page_sk
),
web_sales_agg AS (
    SELECT ws.ws_sold_date_sk          AS date_sk,
           ws.ws_item_sk               AS item_sk,
           ws.ws_promo_sk              AS promo_sk,
           SUM(ws.ws_ext_sales_price)  AS web_sales,
           COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM   web_sales ws
    JOIN   cust_filt c      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN   promo_filt p     ON ws.ws_promo_sk = p.p_promo_sk
    JOIN   date_filt d      ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_promo_sk
),
store_ret_agg AS (
    SELECT sr.sr_returned_date_sk      AS date_sk,
           sr.sr_item_sk               AS item_sk,
           SUM(sr.sr_return_amt)       AS store_returns,
           COUNT(*)                    AS return_cnt
    FROM   store_returns sr
    JOIN   date_filt d      ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk
)
SELECT d.d_year,
       d.d_month_seq,
       i.i_category,
       i.i_brand,
       p.p_promo_name,
       cp.cp_department,
       COALESCE(cs.catalog_sales, 0)   AS total_catalog_sales,
       COALESCE(ws.web_sales, 0)      AS total_web_sales,
       COALESCE(sr.store_returns, 0)  AS total_store_returns,
       COALESCE(cs.catalog_orders, 0) AS catalog_orders,
       COALESCE(ws.web_orders, 0)     AS web_orders,
       COALESCE(sr.return_cnt, 0)     AS return_count
FROM   date_filt d
LEFT JOIN cat_sales_agg cs ON cs.date_sk = d.d_date_sk
LEFT JOIN web_sales_agg ws ON ws.date_sk = d.d_date_sk
                            AND ws.item_sk = cs.item_sk
                            AND ws.promo_sk = cs.promo_sk
LEFT JOIN store_ret_agg sr ON sr.date_sk = d.d_date_sk
                            AND sr.item_sk = cs.item_sk
LEFT JOIN item i            ON i.i_item_sk = cs.item_sk
LEFT JOIN promo_filt p       ON p.p_promo_sk = cs.promo_sk
LEFT JOIN catalog_page cp    ON cp.cp_catalog_page_sk = cs.page_sk
ORDER BY d.d_year,
         d.d_month_seq,
         i.i_category

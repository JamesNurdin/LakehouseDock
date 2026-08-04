/*
Goal: Identify high‑value web sales orders, enriched with customer, item, promotion and time attributes, and combine them with return information (store and web returns). The query first builds a sampled sales fact, unions store and web returns, performs a full outer join to keep unmatched sales or returns, aggregates per order, filters on several business criteria, and finally returns the top orders by profit.
*/
WITH
-- 1. Sample a fraction of the item dimension to reduce scan size
sampled_item AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)   -- approx. 10% of rows
),

-- 2. Central fact table (web_sales) joined to all directly joinable dimensions
joined_fact AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        i.i_category,
        i.i_brand,
        c.c_preferred_cust_flag,
        hd.hd_buy_potential,
        p.p_discount_active,
        tp.t_hour,
        wp.wp_type
    FROM web_sales ws
    JOIN sampled_item i        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c            ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p           ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim tp           ON ws.ws_sold_time_sk = tp.t_time_sk
    JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND hd.hd_buy_potential = '5001-10000'
      AND p.p_discount_active = 'Y'
      AND tp.t_hour BETWEEN 9 AND 17
      AND ws.ws_ext_sales_price > 1000
),

-- 3. Union of store returns and web returns (deduplicated by UNION)
returns_union AS (
    SELECT
        sr.sr_returned_date_sk   AS return_date_sk,
        sr.sr_return_time_sk     AS return_time_sk,
        sr.sr_item_sk            AS item_sk,
        sr.sr_customer_sk        AS customer_sk,
        sr.sr_hdemo_sk           AS hdemo_sk,
        sr.sr_reason_sk          AS reason_sk,
        sr.sr_return_quantity    AS return_quantity,
        sr.sr_return_amt         AS return_amt,
        r.r_reason_desc          AS reason_desc
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    UNION
    SELECT
        wr.wr_returned_date_sk   AS return_date_sk,
        wr.wr_returned_time_sk   AS return_time_sk,
        wr.wr_item_sk            AS item_sk,
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_refunded_hdemo_sk  AS hdemo_sk,
        wr.wr_reason_sk          AS reason_sk,
        wr.wr_return_quantity    AS return_quantity,
        wr.wr_return_amt         AS return_amt,
        r.r_reason_desc          AS reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
),

-- 4. Full outer join sales and returns keeping rows that appear in either side
full_combined AS (
    SELECT
        jf.ws_order_number,
        jf.ws_ext_sales_price,
        jf.ws_net_profit,
        ru.return_quantity,
        ru.return_amt,
        ru.reason_desc
    FROM joined_fact jf
    FULL OUTER JOIN returns_union ru
        ON jf.ws_item_sk = ru.item_sk
),

-- 5. First level aggregation: per order totals
order_agg AS (
    SELECT
        fc.ws_order_number,
        SUM(fc.ws_ext_sales_price)                     AS total_sales,
        SUM(fc.ws_net_profit)                         AS total_profit,
        SUM(COALESCE(fc.return_quantity, 0))          AS total_return_qty,
        SUM(COALESCE(fc.return_amt, 0))               AS total_return_amt
    FROM full_combined fc
    GROUP BY fc.ws_order_number
    HAVING SUM(COALESCE(fc.return_quantity, 0)) > 0   -- keep only orders with at least one return
)
SELECT
    oa.ws_order_number,
    oa.total_sales,
    oa.total_profit,
    oa.total_return_qty,
    oa.total_return_amt,
    oa.total_profit / NULLIF(oa.total_sales, 0) AS profit_margin
FROM order_agg oa
WHERE oa.total_sales > 2000                         -- additional filter on sales amount
ORDER BY oa.total_profit DESC
LIMIT 100

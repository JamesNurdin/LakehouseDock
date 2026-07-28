/* Goal: Identify the top 100 product‑customer combinations for Q2 2001 with the highest net profit after accounting for store and web returns, classify profit levels, and rank each combination within its product. */
WITH sales_agg AS (
    SELECT
        cs.cs_item_sk        AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_sold_date_sk   AS sold_date_sk,
        SUM(cs.cs_net_profit)      AS sales_profit,
        SUM(cs.cs_quantity)        AS sales_qty,
        SUM(cs.cs_ext_sales_price) AS sales_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 2
      AND i.i_category = 'Women'
      AND p.p_discount_active = 'Y'
    GROUP BY cs.cs_item_sk, cs.cs_bill_customer_sk, cs.cs_sold_date_sk
),
store_ret_agg AS (
    SELECT
        sr.sr_item_sk   AS item_sk,
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_return_amt)      AS store_return_amt,
        SUM(sr.sr_return_quantity) AS store_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 2
    GROUP BY sr.sr_item_sk, sr.sr_customer_sk
),
web_ret_agg AS (
    SELECT
        wr.wr_item_sk          AS item_sk,
        wr.wr_returning_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt)          AS web_return_amt,
        SUM(wr.wr_return_quantity)     AS web_return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 2
    GROUP BY wr.wr_item_sk, wr.wr_returning_customer_sk
)
SELECT
    i.i_item_id,
    c.c_customer_id,
    i.i_category,
    c.c_preferred_cust_flag,
    hd.hd_vehicle_count,
    ws.web_state,
    sa.sales_qty,
    sa.sales_amount,
    COALESCE(sr.store_return_amt, 0) + COALESCE(wr.web_return_amt, 0) AS total_return_amt,
    (sa.sales_profit - COALESCE(sr.store_return_amt, 0) - COALESCE(wr.web_return_amt, 0)) AS net_profit,
    CASE
        WHEN (sa.sales_profit - COALESCE(sr.store_return_amt, 0) - COALESCE(wr.web_return_amt, 0)) > 10000 THEN 'HIGH'
        WHEN (sa.sales_profit - COALESCE(sr.store_return_amt, 0) - COALESCE(wr.web_return_amt, 0)) BETWEEN 5000 AND 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY (sa.sales_profit - COALESCE(sr.store_return_amt, 0) - COALESCE(wr.web_return_amt, 0)) DESC) AS rank_within_item,
    -- scalar sub‑query: count of active promotions for the item in the same quarter
    (SELECT COUNT(DISTINCT p2.p_promo_sk)
       FROM promotion p2
       JOIN date_dim d2 ON p2.p_start_date_sk = d2.d_date_sk
       WHERE p2.p_item_sk = i.i_item_sk
         AND d2.d_year = 2001
         AND d2.d_qoy = 2
         AND p2.p_discount_active = 'Y') AS active_promo_cnt
FROM sales_agg sa
JOIN customer c                 ON sa.customer_sk = c.c_customer_sk
JOIN household_demographics hd   ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca        ON c.c_current_addr_sk = ca.ca_address_sk
JOIN item i                     ON sa.item_sk = i.i_item_sk
JOIN web_site ws                ON ws.web_open_date_sk = sa.sold_date_sk
LEFT JOIN store_ret_agg sr       ON sr.item_sk = sa.item_sk AND sr.customer_sk = sa.customer_sk
LEFT JOIN web_ret_agg wr         ON wr.item_sk = sa.item_sk AND wr.customer_sk = sa.customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND hd.hd_vehicle_count > 2
  AND ws.web_state = 'CA'
ORDER BY net_profit DESC
LIMIT 100

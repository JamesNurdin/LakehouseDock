/* goal: Identify high‑profit items sold in 2001 for California stores, adjusting for returns, and rank them by net contribution per year */
WITH per_item_month AS (
    SELECT
        i.i_item_id,
        d1.d_year,
        d1.d_month_seq,
        SUM(cs.cs_net_profit)               AS total_sales_profit,
        SUM(sr.sr_return_amt)               AS total_return_amt,
        COUNT(*)                            AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d1
        ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_returned_date_sk = d1.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d1.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_category = 'Sports'
      AND w.w_state = 'CA'
      AND cs.cs_net_profit > 1000
      AND sr.sr_return_amt > 500
    GROUP BY i.i_item_id, d1.d_year, d1.d_month_seq
)
SELECT
    i_item_id,
    d_year,
    d_month_seq,
    total_sales_profit,
    total_return_amt,
    (total_sales_profit - total_return_amt) AS net_contribution,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (total_sales_profit - total_return_amt) DESC) AS rn_year
FROM per_item_month
WHERE (total_sales_profit - total_return_amt) > 0
ORDER BY d_year DESC, net_contribution DESC
LIMIT 100

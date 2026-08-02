WITH aggregated AS (
    SELECT
        c.c_customer_id,
        cs.cs_item_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(sr.sr_return_amt_inc_tax) AS total_store_return_inc_tax,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        GROUPING(cs.cs_item_sk) AS grp_item,
        GROUPING(c.c_customer_id) AS grp_cust
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE cs.cs_quantity > 5
        AND c.c_current_addr_sk IN (4088514, 3939613, 2000348)
        AND sr.sr_return_amt_inc_tax > 100
        AND wr.wr_reversed_charge < 300
        AND NOT EXISTS (
            SELECT 1
            FROM web_returns wr2
            WHERE wr2.wr_item_sk = wr.wr_item_sk
              AND wr2.wr_returned_date_sk = wr.wr_returned_date_sk
              AND wr2.wr_refunded_customer_sk = c.c_customer_sk
              AND wr2.wr_return_quantity > 0
        )
    GROUP BY ROLLUP (c.c_customer_id, cs.cs_item_sk)
    HAVING SUM(cs.cs_net_paid) > 0
)
SELECT
    c_customer_id,
    cs_item_sk,
    total_net_paid,
    total_store_return_inc_tax,
    total_web_return_amt,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY total_net_paid DESC) AS sales_rank,
    CASE
        WHEN grp_cust = 0 AND grp_item = 0 THEN 'Item Detail'
        WHEN grp_cust = 0 AND grp_item = 1 THEN 'Customer Subtotal'
        WHEN grp_cust = 1 AND grp_item = 1 THEN 'Grand Total'
    END AS row_type
FROM aggregated
ORDER BY c_customer_id NULLS LAST, grp_cust, grp_item

WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
),
customer_year_agg AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(ia.total_qty_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT i.i_item_id) AS distinct_items_returned
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inv_agg ia
        ON ia.inv_item_sk = i.i_item_sk
        AND ia.inv_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND c.c_salutation = 'Mr.'
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND r.r_reason_desc LIKE '%defect%'
      AND wp.wp_type = 'Content'
    GROUP BY c.c_customer_id, d.d_year
)
SELECT
    d_year,
    AVG(total_return_amt) AS avg_return_amt,
    SUM(total_inventory_qty) AS sum_inventory_qty,
    COUNT(*) AS customer_cnt
FROM customer_year_agg
GROUP BY d_year
HAVING AVG(total_return_amt) > 100
ORDER BY d_year DESC
LIMIT 100

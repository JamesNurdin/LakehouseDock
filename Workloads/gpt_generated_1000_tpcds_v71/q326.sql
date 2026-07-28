/* goal: Compare high‑value sales and return transactions for items sold/returned in California during business hours, showing per‑item totals, a status flag, and a row number per item, limited to the top 100 rows. */
WITH sales_data AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        cs.cs_sold_date_sk AS trans_date_sk,
        SUM(cs.cs_ext_sales_price) AS total_amount,
        COUNT(*) AS trans_cnt,
        CASE WHEN MAX(p.p_discount_active) = 'Y' THEN 'Discounted' ELSE 'Regular' END AS status,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY cs.cs_sold_date_sk DESC) AS rn
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_id, i.i_item_desc, cs.cs_sold_date_sk
    HAVING SUM(cs.cs_ext_sales_price) > 1000
),
returns_data AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        cr.cr_returned_date_sk AS trans_date_sk,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(*) AS trans_cnt,
        CASE WHEN r.r_reason_desc = 'Damaged' THEN 'Damaged' ELSE 'Other' END AS status,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY cr.cr_returned_date_sk DESC) AS rn
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_id, i.i_item_desc, cr.cr_returned_date_sk, r.r_reason_desc
    HAVING SUM(cr.cr_return_amount) > 500
)
SELECT
    item_id,
    item_desc,
    trans_date_sk,
    total_amount,
    trans_cnt,
    status,
    rn
FROM sales_data
UNION ALL
SELECT
    item_id,
    item_desc,
    trans_date_sk,
    total_amount,
    trans_cnt,
    status,
    rn
FROM returns_data
ORDER BY total_amount DESC
LIMIT 100

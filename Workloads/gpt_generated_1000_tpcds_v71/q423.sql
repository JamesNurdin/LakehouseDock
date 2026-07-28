WITH sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ca.ca_city,
        cd.cd_credit_rating,
        CASE
            WHEN ss.ss_net_profit > 1000 THEN 'High'
            WHEN ss.ss_net_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(i.i_item_desc, '(?i)steel|iron')
      AND ca.ca_city LIKE 'A%'
),
returns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_id, '^A[0-9]{5}$')
    GROUP BY cr.cr_item_sk
),
agg AS (
    SELECT
        s.i_item_id,
        s.i_item_desc,
        s.ca_city,
        s.profit_category,
        SUM(s.ss_quantity) AS total_quantity_sold,
        SUM(s.ss_net_paid) AS total_net_paid,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        SUM(s.ss_net_profit) - COALESCE(r.total_return_amount, 0) AS net_profit_after_returns,
        regexp_extract(s.i_item_id, '([A-Z]+)', 1) AS brand_prefix,
        CONCAT(s.i_item_desc, ' - ', s.ca_city) AS desc_city
    FROM sales s
    LEFT JOIN returns r ON s.i_item_sk = r.cr_item_sk
    GROUP BY
        s.i_item_id,
        s.i_item_desc,
        s.ca_city,
        s.profit_category,
        r.total_return_amount
)
SELECT
    a.i_item_id,
    a.i_item_desc,
    a.ca_city,
    a.profit_category,
    a.total_quantity_sold,
    a.total_net_paid,
    a.total_return_amount,
    a.net_profit_after_returns,
    a.brand_prefix,
    a.desc_city,
    ROW_NUMBER() OVER (PARTITION BY a.profit_category ORDER BY a.net_profit_after_returns DESC) AS rank_within_category
FROM agg a
ORDER BY a.net_profit_after_returns DESC
LIMIT 100

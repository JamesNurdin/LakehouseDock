WITH sub1 AS (
    SELECT
        d.d_year,
        ca.ca_state,
        w.w_state AS warehouse_state,
        wp.wp_url,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE
            WHEN SUM(sr.sr_net_loss) > 5000 THEN 'High'
            WHEN SUM(sr.sr_net_loss) > 1000 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND ca.ca_state = 'CA'
      AND w.w_state = 'TX'
      AND wp.wp_url LIKE 'http://www.foo.com%'
      AND EXISTS (
          SELECT 1 FROM promotion p
          WHERE p.p_item_sk = sr.sr_item_sk
            AND p.p_start_date_sk = d.d_date_sk
      )
    GROUP BY d.d_year, ca.ca_state, w.w_state, wp.wp_url
),
sub2 AS (
    SELECT DISTINCT
        d.d_year,
        ca.ca_city,
        w.w_city AS warehouse_city,
        wp.wp_type,
        SUM(sr.sr_return_amt) OVER (PARTITION BY d.d_year ORDER BY sr.sr_return_quantity ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt,
        CASE
            WHEN sr.sr_return_quantity > 5 THEN 'Bulk'
            ELSE 'Single'
        END AS order_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND ca.ca_country = 'United States'
      AND w.w_gmt_offset >= -5
      AND wp.wp_type = 'Content'
      AND EXISTS (
          SELECT 1 FROM promotion p
          WHERE p.p_item_sk = sr.sr_item_sk
            AND p.p_end_date_sk = d.d_date_sk
      )
)
SELECT
    year,
    region_state,
    warehouse_state,
    url,
    total_return_amt,
    total_net_loss,
    loss_category,
    RANK() OVER (PARTITION BY year ORDER BY total_return_amt DESC) AS return_rank
FROM (
    SELECT
        d_year AS year,
        ca_state AS region_state,
        warehouse_state,
        wp_url AS url,
        total_return_amt,
        total_net_loss,
        loss_category
    FROM sub1
) a
UNION ALL
SELECT
    year,
    city,
    warehouse_city,
    wp_type,
    cumulative_return_amt,
    NULL AS total_net_loss,
    order_type,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY cumulative_return_amt DESC) AS return_rank
FROM (
    SELECT
        d_year AS year,
        ca_city AS city,
        warehouse_city,
        wp_type,
        cumulative_return_amt,
        order_type
    FROM sub2
) b
ORDER BY year DESC, return_rank
LIMIT 100

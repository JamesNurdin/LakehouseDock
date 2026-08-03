WITH detailed AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        sr.sr_return_amt,
        cr.cr_return_amount,
        i.i_item_id,
        i.i_category,
        t.t_hour,
        ca.ca_country,
        w.w_warehouse_name,
        wp.wp_url,
        ROW_NUMBER() OVER (PARTITION BY sr.sr_store_sk ORDER BY sr.sr_return_amt DESC) AS rn_store_return
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND ca.ca_country = 'United States'
      AND i.i_category = 'Sports'
      AND cr.cr_item_sk IN (
          SELECT i2.i_item_sk FROM item i2 WHERE i2.i_brand = 'BrandX'
      )
)
SELECT
    agg.s_store_name,
    agg.total_return_amount,
    agg.return_count,
    RANK() OVER (ORDER BY agg.total_return_amount DESC) AS store_return_rank,
    agg.sample_url
FROM (
    SELECT
        d.s_store_name,
        SUM(d.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count,
        MIN(d.wp_url) AS sample_url
    FROM detailed d
    GROUP BY d.s_store_name
) agg
ORDER BY agg.total_return_amount DESC
LIMIT 100

WITH filtered AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_account_credit,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_addr_sk,
        wr.wr_item_sk,
        wr.wr_web_page_sk,
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_item_desc,
        i.i_product_name,
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        ca_f.ca_city AS refunded_city,
        ca_f.ca_state AS refunded_state,
        ca_r.ca_city AS returning_city,
        ca_r.ca_state AS returning_state
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca_f
        ON wr.wr_refunded_addr_sk = ca_f.ca_address_sk
    JOIN customer_address ca_r
        ON wr.wr_returning_addr_sk = ca_r.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '\\b[0-9]{3,}\\b')
      AND wp.wp_url LIKE '%shop%'
),
aggregated AS (
    SELECT
        f.i_brand,
        f.i_category,
        f.refunded_city,
        f.refunded_state,
        f.wp_url,
        COUNT(*) AS return_cnt,
        SUM(f.wr_return_amt) AS total_return_amt,
        AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand,
        CASE
            WHEN SUM(f.wr_return_amt) > 1000 THEN 'High'
            WHEN SUM(f.wr_return_amt) > 500 THEN 'Medium'
            ELSE 'Low'
        END AS return_level,
        CONCAT(f.refunded_city, ', ', f.refunded_state) AS refunded_location,
        SUBSTRING(f.wp_url, 1, 30) AS url_prefix
    FROM filtered f
    JOIN inventory inv
        ON inv.inv_item_sk = f.i_item_sk
    GROUP BY
        f.i_brand,
        f.i_category,
        f.refunded_city,
        f.refunded_state,
        f.wp_url
)
SELECT
    a.i_brand,
    a.i_category,
    a.return_cnt,
    a.total_return_amt,
    a.avg_qty_on_hand,
    a.return_level,
    a.refunded_location,
    a.url_prefix,
    ROW_NUMBER() OVER (ORDER BY a.total_return_amt DESC) AS brand_return_rank
FROM aggregated a
ORDER BY a.total_return_amt DESC
LIMIT 100

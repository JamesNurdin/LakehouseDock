WITH filtered_returns AS (
    SELECT
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        i.i_brand AS brand,
        i.i_brand_id AS brand_id,
        i.i_item_desc,
        r.r_reason_desc,
        r.r_reason_id,
        wp.wp_url,
        hd.hd_vehicle_count
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(i.i_item_desc, '(?i)external')
      AND r.r_reason_desc LIKE '%customer%'
      AND wp.wp_url LIKE '%promo%'
      AND hd.hd_vehicle_count >= 0
)
SELECT
    brand,
    brand_id,
    COUNT(*) AS return_cnt,
    SUM(wr_net_loss) AS total_net_loss,
    AVG(wr_return_amt) AS avg_return_amount,
    regexp_extract(r_reason_id, '(\\d+)', 1) AS reason_numeric_id
FROM filtered_returns
GROUP BY
    brand,
    brand_id,
    regexp_extract(r_reason_id, '(\\d+)', 1)
ORDER BY total_net_loss DESC
LIMIT 20

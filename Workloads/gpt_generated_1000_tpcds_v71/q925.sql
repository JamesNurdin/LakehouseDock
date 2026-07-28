WITH sr_data AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_reason_sk,
        sr.sr_customer_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year = 1975
      AND ca.ca_state = 'NY'
      AND i.i_current_price BETWEEN 20 AND 200
      AND r.r_reason_desc LIKE '%size%'
      AND sr.sr_return_quantity > 2
    GROUP BY sr.sr_item_sk, sr.sr_reason_sk, sr.sr_customer_sk
),
wr_data AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_reason_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wp.wp_char_count > 3000
      AND wp.wp_image_count <= 5
      AND wp.wp_max_ad_count <> 0
      AND c.c_birth_year = 1975
      AND ca.ca_state = 'NY'
      AND i.i_current_price BETWEEN 20 AND 200
    GROUP BY wr.wr_item_sk, wr.wr_reason_sk
)
SELECT
    r.r_reason_desc,
    i.i_category,
    sd.store_return_cnt,
    wd.web_return_cnt,
    sd.store_net_loss,
    wd.web_net_loss,
    (sd.store_net_loss + wd.web_net_loss) AS total_net_loss,
    CASE WHEN (sd.store_net_loss + wd.web_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
FROM sr_data sd
JOIN wr_data wd
    ON sd.sr_item_sk = wd.wr_item_sk
   AND sd.sr_reason_sk = wd.wr_reason_sk
JOIN item i
    ON i.i_item_sk = sd.sr_item_sk
JOIN reason r
    ON r.r_reason_sk = sd.sr_reason_sk
JOIN customer c
    ON c.c_customer_sk = sd.sr_customer_sk
WHERE EXISTS (
        SELECT 1
        FROM store_returns sr_ex
        WHERE sr_ex.sr_item_sk = i.i_item_sk
          AND sr_ex.sr_return_quantity > 5
    )
  AND NOT EXISTS (
        SELECT 1
        FROM web_page wp_ex
        WHERE wp_ex.wp_customer_sk = c.c_customer_sk
          AND wp_ex.wp_image_count > 5
    )
ORDER BY loss_category DESC, total_net_loss DESC

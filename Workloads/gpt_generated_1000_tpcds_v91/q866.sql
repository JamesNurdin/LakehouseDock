WITH combined AS (
    SELECT
        c1.c_customer_id AS customer_id,
        c1.c_email_address AS email_address,
        email_token,
        SUM(wr1.wr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns
    FROM web_returns wr1
    JOIN customer c1 ON wr1.wr_refunded_customer_sk = c1.c_customer_sk
    JOIN web_page wp1 ON wr1.wr_web_page_sk = wp1.wp_web_page_sk
    CROSS JOIN UNNEST(split(c1.c_email_address, '@')) AS t(email_token)
    WHERE wp1.wp_image_count > 3
      AND wp1.wp_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND wp1.wp_rec_end_date = (
          SELECT max(wp4.wp_rec_end_date)
          FROM web_page wp4
          WHERE wp4.wp_type = wp1.wp_type
      )
      AND EXISTS (
          SELECT 1
          FROM web_page wp2
          WHERE wp2.wp_web_page_sk = wr1.wr_web_page_sk
            AND wp2.wp_image_count >= 5
      )
    GROUP BY c1.c_customer_id, c1.c_email_address, email_token
    UNION ALL
    SELECT
        c2.c_customer_id AS customer_id,
        c2.c_email_address AS email_address,
        email_token,
        SUM(wr2.wr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns
    FROM web_returns wr2
    JOIN customer c2 ON wr2.wr_returning_customer_sk = c2.c_customer_sk
    JOIN web_page wp2 ON wr2.wr_web_page_sk = wp2.wp_web_page_sk
    CROSS JOIN UNNEST(split(c2.c_email_address, '@')) AS t(email_token)
    WHERE wp2.wp_image_count <= 3
      AND wp2.wp_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2003-12-31'
      AND wp2.wp_rec_end_date = (
          SELECT max(wp5.wp_rec_end_date)
          FROM web_page wp5
          WHERE wp5.wp_type = wp2.wp_type
      )
      AND EXISTS (
          SELECT 1
          FROM web_page wp3
          WHERE wp3.wp_web_page_sk = wr2.wr_web_page_sk
            AND wp3.wp_image_count < 5
      )
    GROUP BY c2.c_customer_id, c2.c_email_address, email_token
)
SELECT
    combined.customer_id,
    combined.email_address,
    combined.email_token,
    combined.total_net_loss,
    combined.total_returns,
    ROW_NUMBER() OVER (ORDER BY combined.total_net_loss DESC) AS loss_rank
FROM combined
ORDER BY loss_rank
LIMIT 100

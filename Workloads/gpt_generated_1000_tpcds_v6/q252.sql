WITH filtered_returns AS (
    SELECT
        wr.wr_returning_customer_sk,
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        i.i_product_name,
        i.i_item_desc,
        wp.wp_url,
        r.r_reason_desc,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(i.i_item_desc, '(?i)coffee|tea')
      AND wp.wp_url LIKE 'http://%store%'
      AND NOT EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = wr.wr_item_sk
            AND p.p_start_date_sk <= wr.wr_returned_date_sk
            AND p.p_end_date_sk   >= wr.wr_returned_date_sk
      )
)
SELECT
    c.c_customer_sk,
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    i.i_product_name,
    COUNT(*) AS return_cnt,
    SUM(fr.wr_net_loss) AS total_net_loss,
    AVG(fr.wr_net_loss) AS avg_net_loss,
    CASE
        WHEN SUM(fr.wr_net_loss) < 0 THEN 'Overall Negative'
        WHEN SUM(fr.wr_net_loss) <= 100 THEN 'Overall Low'
        ELSE 'Overall High'
    END AS overall_loss_category,
    (
        SELECT avg(wr2.wr_net_loss)
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = fr.wr_item_sk
    ) AS item_avg_loss,
    substring(c.c_email_address FROM 1 FOR position('@' IN c.c_email_address) - 1) AS email_user_part,
    regexp_extract(i.i_item_desc, '(?i)(coffee|tea)', 1) AS matched_keyword
FROM filtered_returns fr
JOIN customer c ON fr.wr_returning_customer_sk = c.c_customer_sk
JOIN item i ON fr.wr_item_sk = i.i_item_sk
GROUP BY
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    i.i_product_name,
    i.i_item_desc,
    fr.wr_item_sk
ORDER BY total_net_loss DESC
LIMIT 100

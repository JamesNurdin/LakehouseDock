WITH filtered_returns AS (
    SELECT
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_reason_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        r.r_reason_desc,
        i.i_product_name,
        i.i_class,
        c.c_first_name,
        c.c_last_name,
        wp.wp_url,
        t.t_shift
    FROM web_returns AS wr
    JOIN reason      AS r  ON wr.wr_reason_sk     = r.r_reason_sk
    JOIN item        AS i  ON wr.wr_item_sk       = i.i_item_sk
    JOIN customer    AS c  ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page    AS wp ON wr.wr_web_page_sk  = wp.wp_web_page_sk
    JOIN time_dim    AS t  ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE i.i_class = 'furniture'
      AND regexp_like(r.r_reason_desc, '(?i)not')
      AND wp.wp_url LIKE '%promo%'
      AND t.t_shift = 'second'
)
SELECT
    r_reason_desc,
    regexp_extract(r_reason_desc, '(\\w+)', 1) AS first_word,
    i_product_name,
    concat(c_first_name, ' ', c_last_name) AS customer_name,
    sum(wr_return_amt)        AS total_return_amount,
    sum(wr_return_quantity)   AS total_return_quantity,
    count(*)                  AS return_events
FROM filtered_returns
GROUP BY
    r_reason_desc,
    regexp_extract(r_reason_desc, '(\\w+)', 1),
    i_product_name,
    concat(c_first_name, ' ', c_last_name)
ORDER BY total_return_amount DESC
LIMIT 100

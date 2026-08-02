WITH base AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        r.r_reason_desc,
        wp.wp_url
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE i.i_size = 'extra large'
      AND regexp_like(i.i_product_name, '\\d{3,}')
      AND wp.wp_url LIKE '%sale%'
      AND regexp_like(r.r_reason_desc, '(?i)damaged')
)
SELECT
    b.i_item_id,
    b.i_category,
    b.i_brand,
    concat(b.i_brand, '-', b.i_category) AS brand_category,
    t.word,
    sum(b.wr_return_quantity) AS total_quantity,
    sum(b.wr_return_amt) AS total_return_amount,
    sum(b.wr_net_loss) AS total_net_loss,
    count(DISTINCT b.r_reason_desc) AS distinct_reason_cnt
FROM base b
CROSS JOIN UNNEST(split(b.i_product_name, ' ')) AS t(word)
GROUP BY
    b.i_item_id,
    b.i_category,
    b.i_brand,
    concat(b.i_brand, '-', b.i_category),
    t.word
HAVING
    sum(b.wr_net_loss) > 1000
    AND sum(b.wr_return_amt) > (SELECT avg(wr_return_amt) FROM web_returns) * 1.5
ORDER BY total_net_loss DESC, total_return_amount DESC
LIMIT 100

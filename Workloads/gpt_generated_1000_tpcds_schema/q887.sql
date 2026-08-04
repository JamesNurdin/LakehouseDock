WITH filtered AS (
    SELECT
        i.i_item_sk,
        i.i_manufact_id,
        i.i_brand,
        i.i_category,
        i.i_item_desc,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid_inc_ship,
        ws.ws_ext_wholesale_cost
    FROM tpcds.item i
    JOIN tpcds.web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_item_desc LIKE '%red%'
      AND regexp_like(i.i_item_desc, '^[A-Z]{3,}')
      AND i.i_item_sk NOT IN (
          SELECT ws3.ws_item_sk
          FROM tpcds.web_sales ws3
          WHERE ws3.ws_quantity > 1000
      )
)
SELECT
    f.i_manufact_id,
    f.i_brand,
    f.i_category,
    concat(f.i_brand, '-', f.i_category) AS brand_category,
    COUNT(DISTINCT f.ws_order_number) AS order_cnt,
    SUM(f.ws_net_paid_inc_ship) AS total_net_paid,
    AVG(f.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT w.word) AS distinct_word_cnt,
    (SELECT SUM(ws2.ws_ext_wholesale_cost)
       FROM tpcds.web_sales ws2
       WHERE ws2.ws_item_sk = f.i_item_sk) AS total_wholesale_for_item,
    regexp_extract(f.i_item_desc, '(\\w+)', 1) AS first_word
FROM filtered f
JOIN UNNEST(split(f.i_item_desc, ' ')) AS w(word) ON true
GROUP BY
    f.i_manufact_id,
    f.i_brand,
    f.i_category,
    concat(f.i_brand, '-', f.i_category),
    f.i_item_sk,
    f.i_item_desc
ORDER BY total_net_paid DESC
LIMIT 100

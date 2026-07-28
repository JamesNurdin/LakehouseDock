/* goal: Identify the top items (by combined store and web net loss) that have automotive‑related descriptions and were returned for purchase‑related reasons, showing string‑derived codes and limiting to 100 rows */
WITH store_loss AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(sr.sr_net_loss) AS store_net_loss,
        regexp_extract(r.r_reason_desc, '^([^ ]+)', 1) AS reason_first_word
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE regexp_like(i.i_item_desc, '(?i)auto|engine')
      AND r.r_reason_desc LIKE '%purchase%'
      AND td.t_hour BETWEEN 8 AND 18
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, regexp_extract(r.r_reason_desc, '^([^ ]+)', 1)
)
,
web_loss AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wp.wp_url LIKE '%example.com%'
      AND regexp_like(i.i_item_desc, '(?i)auto|engine')
    GROUP BY wr.wr_item_sk
)
SELECT
    sl.i_item_id,
    sl.i_product_name,
    sl.store_net_loss,
    COALESCE(wl.web_net_loss, 0) AS web_net_loss,
    sl.store_net_loss + COALESCE(wl.web_net_loss, 0) AS total_net_loss,
    substring(sl.i_item_id, 1, 5) AS item_id_prefix,
    sl.reason_first_word || '_' || substring(sl.i_product_name, 1, 3) AS item_reason_code
FROM store_loss sl
LEFT JOIN web_loss wl ON sl.i_item_sk = wl.wr_item_sk
WHERE sl.store_net_loss > 0
ORDER BY total_net_loss DESC
LIMIT 100

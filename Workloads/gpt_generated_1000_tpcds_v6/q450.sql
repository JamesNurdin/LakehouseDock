WITH returns_detail AS (
    SELECT
        wr.wr_net_loss,
        i.i_brand,
        i.i_category,
        i.i_item_id,
        i.i_item_desc,
        r.r_reason_desc,
        p.p_channel_catalog,
        p.p_response_target
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    WHERE
        regexp_like(r.r_reason_desc, '(?i)size')
        AND i.i_item_desc LIKE '%able%'
        AND (p.p_channel_catalog = 'N' OR p.p_channel_catalog IS NULL)
        AND (p.p_response_target = 1 OR p.p_response_target IS NULL)
)
SELECT
    concat(i_brand, '-', i_category) AS brand_category,
    substring(i_item_id, 1, 5) AS item_prefix,
    regexp_extract(i_item_desc, '(\\w+able)', 1) AS extracted_word,
    sum(wr_net_loss) AS total_net_loss,
    count(*) AS returns_count
FROM returns_detail
GROUP BY
    concat(i_brand, '-', i_category),
    substring(i_item_id, 1, 5),
    regexp_extract(i_item_desc, '(\\w+able)', 1)
ORDER BY total_net_loss DESC
LIMIT 100

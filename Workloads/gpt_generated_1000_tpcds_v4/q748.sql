WITH filtered_item AS (
    SELECT
        i_item_sk,
        i_category,
        i_item_desc,
        regexp_extract(i_item_desc, '(?i)(premium|deluxe)', 1) AS matched_word
    FROM item
    WHERE regexp_like(i_item_desc, '(?i)premium')
),

store_agg AS (
    SELECT
        fi.i_category,
        t.t_hour,
        fi.matched_word,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN filtered_item fi
        ON sr.sr_item_sk = fi.i_item_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    GROUP BY fi.i_category, t.t_hour, fi.matched_word
),

catalog_agg AS (
    SELECT
        fi.i_category,
        t.t_hour,
        fi.matched_word,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN filtered_item fi
        ON cr.cr_item_sk = fi.i_item_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type LIKE 'A%'
    GROUP BY fi.i_category, t.t_hour, fi.matched_word
),

web_agg AS (
    SELECT
        fi.i_category,
        t.t_hour,
        fi.matched_word,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN filtered_item fi
        ON wr.wr_item_sk = fi.i_item_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    GROUP BY fi.i_category, t.t_hour, fi.matched_word
)

SELECT
    COALESCE(s.i_category, c.i_category, w.i_category) AS category,
    COALESCE(s.t_hour, c.t_hour, w.t_hour) AS hour,
    COALESCE(s.matched_word, c.matched_word, w.matched_word) AS matched_word,
    COALESCE(s.store_net_loss, 0) + COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.i_category = c.i_category
    AND s.t_hour = c.t_hour
    AND s.matched_word = c.matched_word
FULL OUTER JOIN web_agg w
    ON COALESCE(s.i_category, c.i_category) = w.i_category
    AND COALESCE(s.t_hour, c.t_hour) = w.t_hour
    AND COALESCE(s.matched_word, c.matched_word) = w.matched_word
ORDER BY total_net_loss DESC
LIMIT 100

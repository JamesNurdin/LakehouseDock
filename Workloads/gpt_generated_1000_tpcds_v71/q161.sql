/* goal: Identify the highest‑loss items returned through catalog and web channels, filtering for items whose description contains the word 'blue' and extracting any numeric codes from the description. The query also flags items whose description includes a three‑digit number, aggregates returns by item and hour, and ranks items within each hour by total return amount. */
WITH catalog AS (
    SELECT
        cr.cr_item_sk AS cr_item_sk,
        cr.cr_returned_time_sk AS cr_returned_time_sk,
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_return_tax AS cr_return_tax,
        cr.cr_net_loss AS cr_net_loss,
        i.i_item_desc AS i_item_desc,
        i.i_product_name AS i_product_name,
        t.t_hour AS t_hour,
        t.t_sub_shift AS t_sub_shift,
        CAST(NULL AS VARCHAR) AS wp_url,
        regexp_extract(i.i_item_desc, '(\\d+)', 1) AS extracted_number,
        CASE WHEN regexp_like(i.i_item_desc, '^.*\\d{3}.*$') THEN 1 ELSE 0 END AS desc_has_three_digits
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE i.i_item_desc LIKE '%blue%'
),
web AS (
    SELECT
        wr.wr_item_sk AS cr_item_sk,
        wr.wr_returned_time_sk AS cr_returned_time_sk,
        wr.wr_return_amt AS cr_return_amount,
        wr.wr_return_tax AS cr_return_tax,
        wr.wr_net_loss AS cr_net_loss,
        i.i_item_desc AS i_item_desc,
        i.i_product_name AS i_product_name,
        t.t_hour AS t_hour,
        t.t_sub_shift AS t_sub_shift,
        w.wp_url AS wp_url,
        regexp_extract(i.i_item_desc, '(\\d+)', 1) AS extracted_number,
        CASE WHEN regexp_like(i.i_item_desc, '^.*\\d{3}.*$') THEN 1 ELSE 0 END AS desc_has_three_digits
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page w ON wr.wr_web_page_sk = w.wp_web_page_sk
    WHERE w.wp_url LIKE '%product%'
      AND i.i_item_desc LIKE '%blue%'
),
combined AS (
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM web
),
agg AS (
    SELECT
        cr_item_sk,
        i_product_name,
        t_hour,
        t_sub_shift,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_tax) AS total_return_tax,
        SUM(cr_net_loss) AS total_net_loss,
        MAX(desc_has_three_digits) AS any_desc_three_digits,
        COUNT(*) AS return_events
    FROM combined
    GROUP BY cr_item_sk, i_product_name, t_hour, t_sub_shift
)
SELECT
    cr_item_sk,
    i_product_name,
    t_hour,
    t_sub_shift,
    total_return_amount,
    total_return_tax,
    total_net_loss,
    any_desc_three_digits,
    return_events,
    ROW_NUMBER() OVER (PARTITION BY t_hour ORDER BY total_return_amount DESC) AS rank_by_hour
FROM agg
ORDER BY total_return_amount DESC, rank_by_hour
LIMIT 100

WITH filtered_returns AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_item_sk,
        cr.cr_net_loss,
        cr.cr_returned_time_sk,
        i.i_brand,
        i.i_item_desc,
        w.w_warehouse_name,
        t.t_hour
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
      AND w.w_warehouse_name LIKE '%Center%'
)
SELECT
    w_warehouse_name || ' - ' || i_brand AS warehouse_brand,
    i_brand,
    t_hour,
    regexp_extract(i_item_desc, '([A-Z]{2}[0-9]{3})', 1) AS extracted_code,
    substring(i_item_desc, 1, 15) AS short_desc,
    sum(cr_net_loss) AS total_net_loss,
    count(*) AS return_cnt,
    CASE
        WHEN sum(cr_net_loss) > 10000 THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM filtered_returns
GROUP BY
    w_warehouse_name,
    i_brand,
    t_hour,
    i_item_desc
ORDER BY total_net_loss DESC
LIMIT 100

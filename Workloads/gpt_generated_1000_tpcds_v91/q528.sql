WITH inventory_summary AS (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk
)

SELECT 
    i.i_item_id,
    SUBSTRING(i.i_item_desc FROM 1 FOR 20) AS short_desc,
    regexp_extract(i.i_item_desc, '(\\d+)', 1) AS first_number_extracted,
    t.word,
    inv_sum.total_qty,
    ws_avg_metric.avg_metric AS metric,
    'web_sales' AS source
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inventory_summary inv_sum ON inv_sum.inv_item_sk = i.i_item_sk
LEFT JOIN LATERAL (
    SELECT AVG(ws_ext_discount_amt) AS avg_metric
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = i.i_item_sk
) ws_avg_metric ON TRUE
CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
WHERE regexp_like(i.i_item_desc, '[A-Z]{2,}')
  AND i.i_item_id LIKE concat('ITEM', '%')
  AND EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_item_sk = i.i_item_sk
        AND wr.wr_net_loss > 0
  )
GROUP BY i.i_item_id,
         SUBSTRING(i.i_item_desc FROM 1 FOR 20),
         regexp_extract(i.i_item_desc, '(\\d+)', 1),
         t.word,
         inv_sum.total_qty,
         ws_avg_metric.avg_metric

UNION

SELECT 
    i.i_item_id,
    SUBSTRING(i.i_item_desc FROM 1 FOR 20) AS short_desc,
    regexp_extract(i.i_item_desc, '(\\d+)', 1) AS first_number_extracted,
    t.word,
    inv_sum.total_qty,
    cr_avg_metric.avg_metric AS metric,
    'catalog_returns' AS source
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN inventory_summary inv_sum ON inv_sum.inv_item_sk = i.i_item_sk
LEFT JOIN LATERAL (
    SELECT AVG(cr_net_loss) AS avg_metric
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = i.i_item_sk
) cr_avg_metric ON TRUE
CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
WHERE regexp_like(cp.cp_description, '.*Page.*')
  AND i.i_item_desc LIKE concat('%', 'Color', '%')
  AND cr.cr_return_amount > 100
GROUP BY i.i_item_id,
         SUBSTRING(i.i_item_desc FROM 1 FOR 20),
         regexp_extract(i.i_item_desc, '(\\d+)', 1),
         t.word,
         inv_sum.total_qty,
         cr_avg_metric.avg_metric

ORDER BY total_qty DESC, metric DESC
LIMIT 100

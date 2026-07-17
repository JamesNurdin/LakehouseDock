WITH filtered_inventory AS (
    SELECT inv_date_sk,
           inv_item_sk,
           inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 500
)

SELECT
    d.d_year,
    d.d_fy_quarter_seq,
    i.i_category,
    i.i_brand,
    COUNT(DISTINCT iinv.inv_item_sk) AS distinct_item_count,
    SUM(iinv.inv_quantity_on_hand) AS total_quantity_on_hand,
    AVG(iinv.inv_quantity_on_hand) AS avg_quantity_on_hand
FROM filtered_inventory iinv
JOIN date_dim d
    ON iinv.inv_date_sk = d.d_date_sk
JOIN item i
    ON iinv.inv_item_sk = i.i_item_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_holiday = 'N'
  AND i.i_container = 'Unknown'
  AND i.i_rec_end_date > DATE '2000-12-31'
GROUP BY
    d.d_year,
    d.d_fy_quarter_seq,
    i.i_category,
    i.i_brand
ORDER BY
    d.d_year,
    d.d_fy_quarter_seq,
    total_quantity_on_hand DESC

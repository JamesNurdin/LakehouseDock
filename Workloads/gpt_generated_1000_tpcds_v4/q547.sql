WITH wr_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_web_page_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        COUNT(*) AS cnt_returns,
        MIN(wr.wr_return_tax) AS min_return_tax,
        MAX(wr.wr_return_tax) AS max_return_tax
    FROM web_returns wr
    GROUP BY
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_web_page_sk
)
SELECT
    d.d_date,
    d.d_year,
    t.t_hour,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    inv.inv_quantity_on_hand,
    wp.wp_url,
    wp.wp_type,
    ws.web_name,
    wa.total_return_amt,
    wa.avg_return_qty,
    wa.cnt_returns,
    wa.min_return_tax,
    wa.max_return_tax,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY wa.total_return_amt DESC) AS rn_item
FROM wr_agg wa
JOIN date_dim d
    ON wa.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON wa.wr_returned_time_sk = t.t_time_sk
JOIN item i
    ON wa.wr_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
JOIN web_page wp
    ON wa.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_moy IN (5, 9)
  AND t.t_hour BETWEEN 9 AND 17
  AND i.i_brand = 'Brand#12'
  AND inv.inv_warehouse_sk = 10
  AND wp.wp_type = 'Content'
  AND ws.web_state = 'CA'
ORDER BY wa.total_return_amt DESC
LIMIT 100

WITH date_range AS (
    SELECT d_date_sk, d_date
    FROM tpcds.date_dim
    WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT
    i.i_item_id,
    dr.d_date,
    'sales'      AS record_type,
    SUM(ws.ws_quantity)        AS total_quantity,
    SUM(ws.ws_net_profit)      AS total_amount
FROM tpcds.web_sales ws
JOIN date_range dr         ON ws.ws_sold_date_sk = dr.d_date_sk
JOIN tpcds.item i          ON ws.ws_item_sk = i.i_item_sk
WHERE i.i_brand_id = 1003001
GROUP BY i.i_item_id, dr.d_date

UNION ALL

SELECT
    i.i_item_id,
    dr.d_date,
    'returns'    AS record_type,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_net_loss)        AS total_amount
FROM tpcds.web_returns wr
JOIN date_range dr          ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN tpcds.item i           ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_brand_id = 1003001
GROUP BY i.i_item_id, dr.d_date

ORDER BY total_amount DESC
LIMIT 100

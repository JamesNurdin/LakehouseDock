SELECT
    i_item_id,
    d_year,
    month_seq,
    total_sales,
    profit_indicator,
    channel,
    avg_price_all_items
FROM (
    SELECT
        i.i_item_id AS i_item_id,
        d.d_year AS d_year,
        d.d_month_seq AS month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_indicator,
        'WEB' AS channel,
        (SELECT AVG(i2.i_current_price) FROM item i2) AS avg_price_all_items
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND p.p_start_date_sk <= ws.ws_sold_date_sk
            AND p.p_end_date_sk >= ws.ws_sold_date_sk
      )
    GROUP BY i.i_item_id, d.d_year, d.d_month_seq

    UNION ALL

    SELECT
        i.i_item_id AS i_item_id,
        d.d_year AS d_year,
        d.d_month_seq AS month_seq,
        -SUM(sr.sr_return_amt) AS total_sales,
        CASE WHEN SUM(sr.sr_return_amt) > 0 THEN 'LOSS' ELSE 'PROFIT' END AS profit_indicator,
        'STORE' AS channel,
        (SELECT AVG(i2.i_current_price) FROM item i2) AS avg_price_all_items
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
      AND sr.sr_return_quantity > 0
    GROUP BY i.i_item_id, d.d_year, d.d_month_seq
) AS combined
ORDER BY total_sales DESC, month_seq, i_item_id
LIMIT 100

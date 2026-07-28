WITH
    -- First alias of the time dimension for catalog returns
    td_cr AS (
        SELECT t_time_sk, t_hour
        FROM tpcds.time_dim
    ),
    -- Second alias of the time dimension for web sales
    td_ws AS (
        SELECT t_time_sk, t_hour
        FROM tpcds.time_dim
    ),
    -- Third alias of the time dimension for web returns
    td_wr AS (
        SELECT t_time_sk, t_hour
        FROM tpcds.time_dim
    ),
    -- First alias of the item dimension (used for catalog returns and joins onward)
    i_cr AS (
        SELECT i_item_sk, i_brand
        FROM tpcds.item
    ),
    -- Second alias of the item dimension (used for web returns)
    i_wr AS (
        SELECT i_item_sk, i_brand
        FROM tpcds.item
    ),
    -- First alias of ship mode (used for catalog returns)
    sm_cr AS (
        SELECT sm_ship_mode_sk, sm_type
        FROM tpcds.ship_mode
    ),
    -- Second alias of ship mode (used for web sales)
    sm_ws AS (
        SELECT sm_ship_mode_sk, sm_type
        FROM tpcds.ship_mode
    )
SELECT
    i_cr.i_brand AS brand,
    sm_cr.sm_type AS ship_type,
    td_cr.t_hour AS hour_of_day,
    SUM(cr.cr_net_loss) AS total_catalog_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(wr.wr_net_loss) AS total_web_return_loss
FROM tpcds.catalog_returns cr
INNER JOIN td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
INNER JOIN i_cr ON cr.cr_item_sk = i_cr.i_item_sk
INNER JOIN sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
INNER JOIN tpcds.web_sales ws ON ws.ws_item_sk = i_cr.i_item_sk
INNER JOIN td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
INNER JOIN sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
INNER JOIN tpcds.web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
INNER JOIN td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
INNER JOIN i_wr ON wr.wr_item_sk = i_wr.i_item_sk
WHERE cr.cr_return_amount > 100
  AND ws.ws_list_price > 50
  AND wr.wr_fee > 20
GROUP BY i_cr.i_brand, sm_cr.sm_type, td_cr.t_hour
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY total_catalog_loss DESC
LIMIT 100

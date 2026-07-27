WITH web_sales_part AS (
    SELECT ws.ws_sold_date_sk AS date_key,
           'WebSales' AS source_type,
           ws.ws_net_paid AS amount,
           p.p_promo_name AS detail
    FROM tpcds.web_sales ws
    JOIN tpcds.promotion p        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm       ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_site wsit      ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE p.p_channel_event = 'N'
      AND sm.sm_carrier = 'AIRBORNE'
),
store_returns_part AS (
    SELECT sr.sr_returned_date_sk AS date_key,
           'StoreReturns' AS source_type,
           sr.sr_return_amt AS amount,
           r.r_reason_desc AS detail
    FROM tpcds.store_returns sr
    JOIN tpcds.reason r          ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.time_dim td       ON sr.sr_return_time_sk = td.t_time_sk
    WHERE r.r_reason_desc IS NOT NULL
)
SELECT date_key,
       source_type,
       amount,
       detail
FROM web_sales_part
UNION ALL
SELECT date_key,
       source_type,
       amount,
       detail
FROM store_returns_part
ORDER BY date_key DESC,
         source_type,
         amount DESC
LIMIT 100

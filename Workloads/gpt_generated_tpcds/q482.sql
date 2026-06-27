WITH
    cs_agg AS (
        SELECT
            d.d_year AS year,
            d.d_moy AS month,
            sm.sm_ship_mode_id AS ship_mode,
            cd.cd_gender AS gender,
            cc.cc_name AS call_center_name,
            SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
            SUM(cs.cs_net_profit) AS total_profit,
            SUM(cs.cs_quantity) AS total_quantity
        FROM catalog_sales cs
        JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date < DATE '2002-01-01'
        GROUP BY d.d_year, d.d_moy, sm.sm_ship_mode_id, cd.cd_gender, cc.cc_name
    ),
    ws_agg AS (
        SELECT
            d.d_year AS year,
            d.d_moy AS month,
            sm.sm_ship_mode_id AS ship_mode,
            cd.cd_gender AS gender,
            SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
            SUM(ws.ws_net_profit) AS total_profit,
            SUM(ws.ws_quantity) AS total_quantity
        FROM web_sales ws
        JOIN date_dim d
            ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm
            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_demographics cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date < DATE '2002-01-01'
        GROUP BY d.d_year, d.d_moy, sm.sm_ship_mode_id, cd.cd_gender
    ),
    cr_agg AS (
        SELECT
            d.d_year AS year,
            d.d_moy AS month,
            sm.sm_ship_mode_id AS ship_mode,
            cc.cc_name AS call_center_name,
            SUM(cr.cr_net_loss) AS total_net_loss,
            SUM(cr.cr_return_quantity) AS total_return_quantity,
            COUNT(*) AS return_count
        FROM catalog_returns cr
        JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date < DATE '2002-01-01'
        GROUP BY d.d_year, d.d_moy, sm.sm_ship_mode_id, cc.cc_name
    )
SELECT
    COALESCE(cs.year, ws.year, cr.year) AS year,
    COALESCE(cs.month, ws.month, cr.month) AS month,
    COALESCE(cs.ship_mode, ws.ship_mode, cr.ship_mode) AS ship_mode,
    cs.gender,
    cs.call_center_name AS catalog_call_center,
    cs.total_net_paid AS catalog_net_paid,
    ws.total_net_paid AS web_net_paid,
    cr.total_net_loss AS catalog_return_loss,
    cs.total_profit AS catalog_profit,
    ws.total_profit AS web_profit,
    cs.total_quantity AS catalog_quantity,
    ws.total_quantity AS web_quantity,
    cr.total_return_quantity AS return_quantity,
    cr.return_count AS return_transactions
FROM cs_agg cs
FULL OUTER JOIN ws_agg ws
    ON cs.year = ws.year
   AND cs.month = ws.month
   AND cs.ship_mode = ws.ship_mode
   AND cs.gender = ws.gender
FULL OUTER JOIN cr_agg cr
    ON COALESCE(cs.year, ws.year) = cr.year
   AND COALESCE(cs.month, ws.month) = cr.month
   AND COALESCE(cs.ship_mode, ws.ship_mode) = cr.ship_mode
ORDER BY year, month, ship_mode, gender

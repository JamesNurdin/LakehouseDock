WITH ss_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
ranked AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        sm.sm_code,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY ws.ws_ext_sales_price DESC) AS gender_rank,
        const.val AS const_val
    FROM ss_sample ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    CROSS JOIN (VALUES 1, 2, 3) AS const(val)
    WHERE cd.cd_gender = 'M'
      AND ws.ws_ext_list_price > 3000
      AND wsite.web_rec_start_date >= DATE '2001-01-01'
)
SELECT
    cd_gender,
    cd_marital_status,
    ws_web_site_sk,
    ws_ship_mode_sk,
    sm_code,
    ws_ext_sales_price,
    ws_net_paid,
    gender_rank,
    const_val
FROM ranked
WHERE gender_rank <= 5
ORDER BY cd_gender, gender_rank

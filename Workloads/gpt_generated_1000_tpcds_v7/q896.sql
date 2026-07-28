WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_brand,
        cs.cs_net_profit AS cs_profit,
        cs.cs_quantity AS cs_quantity,
        ws.ws_net_profit AS ws_profit,
        ws.ws_quantity AS ws_quantity,
        sr.sr_net_loss AS sr_loss
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_site wsit ON wsit.web_open_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_web_page_sk = wp.wp_web_page_sk
        AND ws.ws_web_site_sk = wsit.web_site_sk
    WHERE d.d_year = 2000
      AND i.i_brand = 'Brand1'
      AND cs.cs_quantity > 10
      AND ws.ws_quantity > 5
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        i_item_id,
        SUM(cs_profit) AS sum_cs_profit,
        SUM(ws_profit) AS sum_ws_profit,
        SUM(sr_loss) AS sum_sr_loss
    FROM base
    GROUP BY d_year, d_month_seq, i_item_id
)
SELECT
    d_year,
    d_month_seq,
    AVG(total_net) AS avg_total_net
FROM (
    SELECT
        d_year,
        d_month_seq,
        (sum_cs_profit + sum_ws_profit - sum_sr_loss) AS total_net
    FROM agg
) t
GROUP BY d_year, d_month_seq
HAVING AVG(total_net) > 1000
ORDER BY d_year, d_month_seq

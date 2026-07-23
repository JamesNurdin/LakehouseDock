/* Goal: Identify and rank stores by their net loss across store sales, store returns, catalog returns, and web returns, filtered by business hour, customer birth country, gender, household vehicle count, and high‑priced web sales, and label each store as high or low loss based on the overall average net loss. */
WITH base AS (
    SELECT
        t.t_hour,
        c.c_birth_country,
        cd.cd_gender,
        hd.hd_vehicle_count,
        ws.ws_list_price,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        ss.ss_net_profit AS ss_net_profit,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_net_loss AS cr_net_loss,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_net_loss AS wr_net_loss
    FROM time_dim t
    JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
),
store_agg AS (
    SELECT
        s_store_id,
        s_store_name,
        s_state,
        SUM(ss_net_profit) AS total_store_sales_profit,
        SUM(sr_net_loss) AS total_store_returns_loss,
        SUM(cr_net_loss) AS total_catalog_returns_loss,
        SUM(ws_net_profit) AS total_web_sales_profit,
        SUM(wr_net_loss) AS total_web_returns_loss,
        (SUM(sr_net_loss) + SUM(cr_net_loss) + SUM(wr_net_loss) - SUM(ss_net_profit) - SUM(ws_net_profit)) AS net_loss
    FROM base
    WHERE t_hour BETWEEN 9 AND 17
      AND c_birth_country IN ('IRELAND', 'KOREA')
      AND cd_gender = 'M'
      AND hd_vehicle_count >= 2
      AND ws_list_price > 100
    GROUP BY s_store_id, s_store_name, s_state
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    total_store_sales_profit,
    total_store_returns_loss,
    total_catalog_returns_loss,
    total_web_sales_profit,
    total_web_returns_loss,
    net_loss,
    RANK() OVER (ORDER BY net_loss DESC) AS loss_rank,
    CASE
        WHEN net_loss > (SELECT AVG(net_loss) FROM store_agg) THEN 'High' ELSE 'Low'
    END AS loss_category
FROM store_agg
ORDER BY loss_rank
LIMIT 100

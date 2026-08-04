WITH joined_data AS (
    SELECT
        s.s_state,
        i.i_category,
        td.t_hour,
        p.p_promo_name,
        ss.ss_net_profit AS store_profit,
        ws.ws_net_profit AS web_profit,
        sr.sr_net_loss  AS store_return_loss,
        wr.wr_net_loss  AS web_return_loss,
        CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN (
        SELECT * FROM item TABLESAMPLE BERNOULLI (10)
    ) i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = ss.ss_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE i.i_size IN ('medium', 'small')
      AND p.p_cost > 500
      AND s.s_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
)
,
aggregated AS (
    SELECT
        s_state,
        i_category,
        purchase_type,
        (store_profit + web_profit) AS total_profit,
        (store_return_loss + web_return_loss) AS total_loss
    FROM joined_data
)
SELECT
    s_state,
    i_category,
    purchase_type,
    AVG(total_profit) AS avg_profit,
    SUM(total_loss)   AS sum_loss
FROM aggregated
GROUP BY CUBE (s_state, i_category, purchase_type)
HAVING AVG(total_profit) > 0
ORDER BY avg_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

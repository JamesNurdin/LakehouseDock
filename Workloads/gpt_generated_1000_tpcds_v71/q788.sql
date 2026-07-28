WITH all_data AS (
    SELECT
        s.s_store_id,
        s.s_state,
        wsit.web_site_id,
        wsit.web_country,
        t.t_hour,
        cd.cd_gender,
        hd.hd_buy_potential,
        ss.ss_net_profit,
        sr.sr_net_loss,
        ws.ws_net_profit,
        wp.wp_type,
        cp.cp_catalog_page_id,
        cp.cp_type,
        cr.cr_net_loss,
        r.r_reason_desc
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t            ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk
                                 AND ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r         ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr ON t.t_time_sk = cr.cr_returned_time_sk
                                   AND cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
    LEFT JOIN catalog_page cp   ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_sales ws     ON t.t_time_sk = ws.ws_sold_time_sk
                                   AND cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    LEFT JOIN web_site wsit    ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN web_page wp      ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
store_agg AS (
    SELECT
        'Store' AS channel,
        s_store_id    AS entity_id,
        t_hour,
        SUM(ss_net_profit)               AS total_profit,
        SUM(COALESCE(sr_net_loss, 0))    AS total_loss,
        (SELECT max(ib_upper_bound) FROM income_band) AS max_income
    FROM all_data
    WHERE s_store_id IS NOT NULL
      AND s_state = 'CA'
      AND t_hour BETWEEN 9 AND 17
      AND cd_gender = 'M'
      AND hd_buy_potential = '500-1000'
      AND EXISTS (SELECT 1 FROM reason r2 WHERE r2.r_reason_desc LIKE '%damage%')
    GROUP BY GROUPING SETS (
        (s_store_id, t_hour),
        (s_store_id),
        ()
    )
),
web_agg AS (
    SELECT
        'Web' AS channel,
        web_site_id AS entity_id,
        t_hour,
        SUM(ws_net_profit)            AS total_profit,
        0.0                           AS total_loss,
        (SELECT max(ib_upper_bound) FROM income_band) AS max_income
    FROM all_data
    WHERE web_site_id IS NOT NULL
      AND web_country = 'United States'
      AND t_hour BETWEEN 9 AND 17
      AND cd_gender = 'M'
      AND hd_buy_potential = '500-1000'
      AND wp_type = 'Content'
    GROUP BY GROUPING SETS (
        (web_site_id, t_hour),
        (web_site_id),
        ()
    )
)
SELECT
    channel,
    entity_id,
    t_hour,
    total_profit,
    total_loss,
    max_income,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) combined
ORDER BY channel, profit_rank
LIMIT 100

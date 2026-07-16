SELECT d_year,
       state,
       sum(net_amount) AS total_net_profit
FROM (
    SELECT d.d_year AS d_year,
           s.s_state AS state,
           ss.ss_net_profit AS net_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk

    UNION ALL

    SELECT d.d_year,
           s.s_state,
           -sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk

    UNION ALL

    SELECT d.d_year,
           cc.cc_state,
           cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk

    UNION ALL

    SELECT d.d_year,
           cc.cc_state,
           -cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk

    UNION ALL

    SELECT d.d_year,
           ws_state.web_state,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_state ON ws.ws_web_site_sk = ws_state.web_site_sk
) t
WHERE d_year BETWEEN 1999 AND 2002
GROUP BY d_year, state
ORDER BY d_year, state

WITH band_avg AS (
    SELECT ib.ib_income_band_sk,
           AVG(ws.ws_net_profit) AS avg_band_profit
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT
    s.s_store_id,
    wsit.web_site_id,
    ib.ib_income_band_sk,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(wr.wr_net_loss) AS total_web_returns_loss,
    (SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss)) AS net_total,
    CASE WHEN (SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss)) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    band_avg.avg_band_profit,
    RANK() OVER (PARTITION BY wsit.web_site_id ORDER BY (SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss)) DESC) AS store_rank_in_site
FROM store s
JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
JOIN item i ON i.i_item_sk = sr.sr_item_sk
JOIN customer c ON c.c_customer_sk = sr.sr_customer_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = sr.sr_cdemo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = sr.sr_hdemo_sk
JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN web_site wsit ON wsit.web_site_sk = ws.ws_web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN band_avg ON band_avg.ib_income_band_sk = ib.ib_income_band_sk
WHERE s.s_state = 'IN'
  AND i.i_current_price > 20
  AND hd.hd_buy_potential = '>10000'
GROUP BY
    s.s_store_id,
    wsit.web_site_id,
    ib.ib_income_band_sk,
    band_avg.avg_band_profit
ORDER BY net_total DESC
LIMIT 100

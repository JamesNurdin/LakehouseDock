WITH sales_returns AS (
    SELECT
        ws.ws_web_site_sk AS site_sk,
        ws.ws_net_profit,
        wr.wr_return_amt,
        hd.hd_buy_potential,
        wsit.web_name
    FROM tpcds.web_sales ws
    JOIN tpcds.web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN tpcds.web_returns wr
        ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
    WHERE wsit.web_name LIKE '%Web%'
      AND regexp_like(wsit.web_name, '^.*[A-Z]{2,}.*$')
)
SELECT
    sr.site_sk,
    CONCAT(sr.web_name, '-', CAST(sr.site_sk AS VARCHAR)) AS site_label,
    regexp_extract(sr.web_name, '([A-Za-z]+)', 1) AS name_prefix,
    sr.hd_buy_potential,
    SUM(sr.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.wr_return_amt, 0)) AS total_return_amount,
    CASE
        WHEN SUM(sr.ws_net_profit) > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END AS profit_flag
FROM sales_returns sr
GROUP BY sr.site_sk, sr.web_name, sr.hd_buy_potential
ORDER BY total_net_profit DESC
LIMIT 100

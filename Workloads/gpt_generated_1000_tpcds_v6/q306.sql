WITH filtered_sales AS (
    SELECT
        ws.ws_bill_hdemo_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_sales_price
    FROM web_sales ws
    WHERE ws.ws_quantity > 1
)
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    substring(hd.hd_buy_potential, 1, 3) AS buy_potential_prefix,
    concat('Potential-', hd.hd_buy_potential) AS potential_tag,
    COUNT(*) AS sale_count,
    SUM(fs.ws_net_profit) AS total_profit,
    AVG(fs.ws_net_profit) AS avg_profit,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS overall_avg_profit
FROM filtered_sales fs
JOIN household_demographics hd
    ON fs.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE
    regexp_like(hd.hd_buy_potential, '^A[0-9]{2}$')
    AND hd.hd_buy_potential LIKE '%HIGH%'
GROUP BY
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    substring(hd.hd_buy_potential, 1, 3),
    concat('Potential-', hd.hd_buy_potential)
ORDER BY total_profit DESC
LIMIT 100

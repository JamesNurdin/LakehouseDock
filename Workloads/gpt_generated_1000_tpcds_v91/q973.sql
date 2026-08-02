WITH filtered_sales AS (
    SELECT
        ws_bill_hdemo_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ws_ext_sales_price
    FROM tpcds.web_sales
    WHERE ws_quantity > 5
)
SELECT
    hs.hd_buy_potential,
    regexp_extract(hs.hd_buy_potential, '([0-9]+)-', 1) AS lower_bound_range,
    SUM(fs.ws_net_profit) AS total_net_profit,
    AVG(fs.ws_ext_sales_price) AS avg_ext_sales_price,
    COUNT(*) AS sales_transactions,
    concat('Potential ', hs.hd_buy_potential) AS buy_potential_label,
    substring(hs.hd_buy_potential, 1, 4) AS prefix_4chars
FROM filtered_sales fs
JOIN tpcds.household_demographics hs
    ON fs.ws_bill_hdemo_sk = hs.hd_demo_sk
WHERE regexp_like(hs.hd_buy_potential, '^[0-9]+-[0-9]+$')
  AND hs.hd_buy_potential LIKE '%-%'
  AND EXISTS (
      SELECT 1
      FROM tpcds.web_sales ws_check
      WHERE ws_check.ws_item_sk = fs.ws_item_sk
        AND ws_check.ws_net_profit > 1000
  )
GROUP BY
    hs.hd_buy_potential,
    regexp_extract(hs.hd_buy_potential, '([0-9]+)-', 1),
    concat('Potential ', hs.hd_buy_potential),
    substring(hs.hd_buy_potential, 1, 4)
HAVING
    SUM(fs.ws_net_profit) > (
        SELECT AVG(ws_net_profit)
        FROM tpcds.web_sales
    )
ORDER BY total_net_profit DESC
LIMIT 100

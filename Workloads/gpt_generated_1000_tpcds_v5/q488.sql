WITH sales_joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_quantity AS store_quantity,
        ss.ss_net_profit AS store_profit,
        ws.ws_quantity AS web_quantity,
        ws.ws_net_profit AS web_profit,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_sold_time_sk,
        ws.ws_web_site_sk
    FROM store_sales ss
    JOIN web_sales ws
        ON ws.ws_item_sk = ss.ss_item_sk
        AND ws.ws_sold_time_sk = ss.ss_sold_time_sk
    WHERE ss.ss_quantity > 0
      AND ws.ws_quantity > 0
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_category_id,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    wsit.web_name,
    AVG(td.t_hour) AS avg_hour,
    SUM(inv.inv_quantity_on_hand) AS total_on_hand,
    SUM(sj.store_quantity) AS total_store_quantity,
    SUM(sj.web_quantity) AS total_web_quantity,
    SUM(sj.store_profit) AS total_store_profit,
    SUM(sj.web_profit) AS total_web_profit,
    (SUM(sj.store_profit) + SUM(sj.web_profit)) AS total_profit,
    RANK() OVER (PARTITION BY i.i_category_id ORDER BY (SUM(sj.store_profit) + SUM(sj.web_profit)) DESC) AS category_profit_rank
FROM sales_joined sj
JOIN store_sales ss
    ON ss.ss_item_sk = sj.ss_item_sk
    AND ss.ss_sold_time_sk = sj.ss_sold_time_sk
    AND ss.ss_hdemo_sk = sj.ss_hdemo_sk
JOIN web_sales ws
    ON ws.ws_item_sk = sj.ss_item_sk
    AND ws.ws_sold_time_sk = sj.ss_sold_time_sk
    AND ws.ws_web_site_sk = sj.ws_web_site_sk
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE i.i_category_id = 4
  AND i.i_rec_end_date > DATE '2000-01-01'
  AND ib.ib_lower_bound >= 50000
  AND td.t_hour BETWEEN 12 AND 14
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_category_id,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    wsit.web_name
ORDER BY total_profit DESC

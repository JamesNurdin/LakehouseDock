WITH sampled_ws AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
    WHERE ws_sold_date_sk IS NOT NULL
)
SELECT
    d_sold.d_date AS sale_date,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    p.p_promo_name,
    sm.sm_code AS shipping_code,
    cc.cc_name,
    hd_bill.hd_buy_potential,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY ws.ws_net_profit DESC) AS profit_rank_in_promo,
    SUM(ws.ws_net_profit) OVER (
        PARTITION BY sm.sm_code
        ORDER BY d_sold.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_by_ship,
    (
        SELECT SUM(sr2.sr_return_quantity)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = ws.ws_item_sk
          AND sr2.sr_returned_date_sk = ws.ws_sold_date_sk
    ) AS total_returns_for_item_on_date
FROM sampled_ws ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk AND cp.cp_end_date_sk = d_ship.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d_sold.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk
    AND sr.sr_return_time_sk = t_sold.t_time_sk
    AND sr.sr_hdemo_sk = hd_bill.hd_demo_sk
WHERE
    d_sold.d_year = 2020
    AND d_ship.d_month_seq BETWEEN 202001 AND 202012
    AND p.p_discount_active = 'Y'
    AND sm.sm_code = 'AIR       '
    AND cc.cc_division = 3
    AND inv.inv_quantity_on_hand > 100
    AND hd_bill.hd_income_band_sk = 5
    AND cp.cp_type = 'Web'
ORDER BY profit_rank_in_promo
LIMIT 100

WITH joined AS (
    SELECT
        ca.ca_state AS ca_state,
        ib.ib_upper_bound AS ib_upper_bound,
        d_s.d_year AS d_year,
        cd.cd_gender AS cd_gender,
        sm.sm_type AS sm_type,
        ss.ss_net_profit AS ss_profit,
        ws.ws_net_profit AS ws_profit,
        ss.ss_quantity AS ss_qty,
        ws.ws_quantity AS ws_qty,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d_s
        ON ss.ss_sold_date_sk = d_s.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_s.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_s.d_date_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    -- additional aliases of the same dimension tables for different roles
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
)
SELECT
    ca_state,
    ib_upper_bound,
    d_year,
    cd_gender,
    sm_type,
    CASE WHEN ib_upper_bound > 150000 THEN 'High' ELSE 'Medium' END AS income_category,
    SUM(ss_profit + ws_profit) AS total_profit,
    SUM(ss_qty + ws_qty) AS total_quantity,
    AVG(inv_quantity_on_hand) AS avg_inventory,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(ss_profit + ws_profit) DESC) AS profit_rank
FROM joined
GROUP BY
    ca_state,
    ib_upper_bound,
    d_year,
    cd_gender,
    sm_type,
    CASE WHEN ib_upper_bound > 150000 THEN 'High' ELSE 'Medium' END
ORDER BY total_profit DESC
LIMIT 100

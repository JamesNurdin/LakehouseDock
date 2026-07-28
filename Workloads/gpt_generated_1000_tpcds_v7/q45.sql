WITH joined_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_name,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        sm.sm_type,
        r.r_reason_desc,
        i.i_brand,
        i.i_category,
        inv.inv_quantity_on_hand,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        ca.ca_county,
        c.c_first_name,
        c.c_last_name,
        c.c_customer_sk AS customer_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_net_profit,
        ws.ws_quantity,
        tm.t_hour
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim tm
        ON cr.cr_returned_time_sk = tm.t_time_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_ship_date_sk = d.d_date_sk
)
SELECT
    d_year,
    cc_name,
    i_brand,
    i_category,
    hd_buy_potential,
    ib_lower_bound,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    SUM(ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT customer_sk) AS unique_customers,
    AVG(ws_quantity) AS avg_web_quantity
FROM joined_data
WHERE
    d_year BETWEEN 1998 AND 2000
    AND cc_name LIKE '%Online%'
    AND ca_county = 'Maricopa County'
    AND hd_buy_potential = '500+'
    AND ib_upper_bound >= 100000
    AND t_hour >= 12
GROUP BY
    d_year,
    cc_name,
    i_brand,
    i_category,
    hd_buy_potential,
    ib_lower_bound
HAVING
    SUM(ws_net_profit) > 10000
ORDER BY
    total_web_profit DESC,
    d_year
LIMIT 100

WITH joined AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit               AS store_net_profit,
        sr.sr_net_loss                 AS store_net_loss,
        sr.sr_return_amt               AS store_return_amt,
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit               AS web_net_profit,
        wr.wr_net_loss                 AS web_net_loss,
        wr.wr_return_amt               AS web_return_amt,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r_store.r_reason_desc          AS store_return_reason,
        r_web.r_reason_desc            AS web_return_reason,
        ca.ca_state,
        ws.ws_coupon_amt
    FROM store_sales ss
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r_store
        ON sr.sr_reason_sk = r_store.r_reason_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
       AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
       AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r_web
        ON wr.wr_reason_sk = r_web.r_reason_sk
    WHERE ib.ib_lower_bound >= 90000
      AND ib.ib_upper_bound <= 200000
      AND r_store.r_reason_desc LIKE '%price%'
      AND cd.cd_gender = 'M'
      AND ws.ws_coupon_amt > 1000
)
SELECT
    cd_demo_sk,
    cd_gender,
    hd_buy_potential,
    ib_lower_bound,
    SUM(store_net_profit)               AS total_store_profit,
    SUM(web_net_profit)                 AS total_web_profit,
    SUM(store_net_profit) + SUM(web_net_profit) AS combined_profit,
    CASE
        WHEN SUM(store_net_profit) + SUM(web_net_profit) > 50000 THEN 'High'
        WHEN SUM(store_net_profit) + SUM(web_net_profit) > 20000 THEN 'Medium'
        ELSE 'Low'
    END                                 AS profit_category,
    ROW_NUMBER() OVER (ORDER BY SUM(store_net_profit) + SUM(web_net_profit) DESC) AS profit_rank
FROM joined
GROUP BY cd_demo_sk, cd_gender, hd_buy_potential, ib_lower_bound
ORDER BY combined_profit DESC
LIMIT 100

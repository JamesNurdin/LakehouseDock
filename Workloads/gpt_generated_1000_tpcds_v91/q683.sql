WITH filtered_sales AS (
    SELECT
        d.d_date,
        d.d_year,
        ss.ss_item_sk,
        cs.cs_item_sk AS cs_item_sk,
        ss.ss_quantity,
        cs.cs_quantity,
        ss.ss_ext_sales_price,
        cs.cs_ext_sales_price,
        ss.ss_net_profit,
        cs.cs_net_profit,
        sr.sr_net_loss,
        inv.inv_quantity_on_hand,
        cc.cc_name,
        cc.cc_state,
        hd_ss.hd_income_band_sk,
        hd_ss.hd_buy_potential,
        hd_cs.hd_buy_potential AS hd_cs_buy_potential
    FROM
        (SELECT * FROM date_dim TABLESAMPLE BERNOULLI (10)) d
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd_ss
            ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        JOIN inventory inv
            ON inv.inv_date_sk = d.d_date_sk
        JOIN catalog_sales cs
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN household_demographics hd_cs
            ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
        LEFT OUTER JOIN store_returns sr
            ON sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2002
        AND cc.cc_state = 'CA'
        AND ss.ss_quantity > 5
        AND cs.cs_sales_price > 20
        AND inv.inv_quantity_on_hand > 100
        AND EXISTS (
            SELECT 1
            FROM inventory inv2
            WHERE inv2.inv_item_sk = ss.ss_item_sk
              AND inv2.inv_quantity_on_hand > 500
        )
)

SELECT
    d_date,
    d_year,
    ss_item_sk,
    cs_item_sk,
    cc_name,
    ss_quantity,
    cs_quantity,
    ss_ext_sales_price,
    cs_ext_sales_price,
    COALESCE(sr_net_loss, 0) AS return_loss,
    (ss_net_profit + cs_net_profit) AS total_profit,
    ((ss_net_profit + cs_net_profit) - COALESCE(sr_net_loss, 0)) AS adjusted_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY (ss_net_profit + cs_net_profit) DESC) AS profit_rank_year,
    DENSE_RANK() OVER (PARTITION BY d_year ORDER BY inv_quantity_on_hand DESC) AS inventory_rank,
    (SELECT avg(cs2.cs_net_profit)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = cs_item_sk) AS avg_item_profit
FROM filtered_sales
ORDER BY profit_rank_year, d_date DESC
LIMIT 100

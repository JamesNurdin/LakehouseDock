WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk,
             cs.cs_promo_sk,
             cs.cs_warehouse_sk,
             cs.cs_bill_customer_sk,
             cs.cs_ship_customer_sk,
             cs.cs_bill_hdemo_sk,
             cs.cs_ship_hdemo_sk
),
returns_agg AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        CAST(NULL AS integer) AS promo_sk,
        CAST(NULL AS integer) AS warehouse_sk,
        CAST(NULL AS integer) AS bill_customer_sk,
        CAST(NULL AS integer) AS ship_customer_sk,
        CAST(NULL AS integer) AS bill_hdemo_sk,
        CAST(NULL AS integer) AS ship_hdemo_sk,
        CAST(0 AS decimal(7,2)) AS total_sales,
        CAST(0 AS decimal(7,2)) AS total_profit,
        0 AS sales_cnt,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
combined AS (
    SELECT
        s.cs_item_sk AS item_sk,
        s.cs_promo_sk AS promo_sk,
        s.cs_warehouse_sk AS warehouse_sk,
        s.cs_bill_customer_sk AS bill_customer_sk,
        s.cs_ship_customer_sk AS ship_customer_sk,
        s.cs_bill_hdemo_sk AS bill_hdemo_sk,
        s.cs_ship_hdemo_sk AS ship_hdemo_sk,
        s.total_sales,
        s.total_profit,
        s.sales_cnt,
        CAST(0 AS integer) AS total_return_quantity,
        CAST(0 AS decimal(7,2)) AS total_return_amount,
        CAST(0 AS decimal(7,2)) AS total_loss,
        0 AS returns_cnt
    FROM sales_agg s
    UNION ALL
    SELECT
        r.item_sk,
        r.promo_sk,
        r.warehouse_sk,
        r.bill_customer_sk,
        r.ship_customer_sk,
        r.bill_hdemo_sk,
        r.ship_hdemo_sk,
        r.total_sales,
        r.total_profit,
        r.sales_cnt,
        r.total_return_quantity,
        r.total_return_amount,
        r.total_loss,
        r.returns_cnt
    FROM returns_agg r
)
SELECT
    i.i_item_id,
    i.i_product_name,
    p_combo.p_promo_name,
    p_item.p_promo_name AS item_promo_name,
    w.w_warehouse_name,
    hd_bill.hd_buy_potential AS bill_buy_potential,
    hd_ship.hd_buy_potential AS ship_buy_potential,
    hd_cust_bill.hd_buy_potential AS cust_bill_buy_potential,
    SUM(combined.total_sales) AS total_sales_amount,
    SUM(combined.total_profit) AS total_profit_amount,
    SUM(combined.total_return_quantity) AS total_return_quantity,
    SUM(combined.total_return_amount) AS total_return_amount,
    SUM(combined.total_loss) AS total_loss_amount,
    SUM(combined.sales_cnt) AS total_sales_transactions,
    SUM(combined.returns_cnt) AS total_return_transactions,
    (SUM(combined.total_sales) - SUM(combined.total_loss)) AS net_sales_loss
FROM combined
FULL OUTER JOIN item i
    ON combined.item_sk = i.i_item_sk
LEFT JOIN promotion p_combo
    ON combined.promo_sk = p_combo.p_promo_sk
LEFT JOIN promotion p_item
    ON i.i_item_sk = p_item.p_item_sk
LEFT JOIN warehouse w
    ON combined.warehouse_sk = w.w_warehouse_sk
LEFT JOIN customer cb
    ON combined.bill_customer_sk = cb.c_customer_sk
LEFT JOIN customer cs
    ON combined.ship_customer_sk = cs.c_customer_sk
LEFT JOIN household_demographics hd_bill
    ON combined.bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN household_demographics hd_ship
    ON combined.ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN household_demographics hd_cust_bill
    ON cb.c_current_hdemo_sk = hd_cust_bill.hd_demo_sk
GROUP BY
    i.i_item_id,
    i.i_product_name,
    p_combo.p_promo_name,
    p_item.p_promo_name,
    w.w_warehouse_name,
    hd_bill.hd_buy_potential,
    hd_ship.hd_buy_potential,
    hd_cust_bill.hd_buy_potential
ORDER BY net_sales_loss DESC
LIMIT 100

WITH
    inventory_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        WHERE inv_quantity_on_hand > 0
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    store_sales_agg AS (
        SELECT
            ss_item_sk,
            ss_cdemo_sk,
            ss_hdemo_sk,
            SUM(ss_ext_sales_price) AS total_sales,
            SUM(ss_net_profit) AS total_profit
        FROM store_sales
        WHERE ss_quantity > 0
          AND ss_ext_sales_price > 100
        GROUP BY ss_item_sk, ss_cdemo_sk, ss_hdemo_sk
    ),
    catalog_returns_agg AS (
        SELECT
            cr_item_sk,
            cr_refunded_cdemo_sk,
            cr_refunded_hdemo_sk,
            cr_warehouse_sk,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(cr_net_loss) AS total_return_loss
        FROM catalog_returns
        WHERE cr_return_quantity > 0
          AND cr_return_amount > 0
        GROUP BY cr_item_sk, cr_refunded_cdemo_sk, cr_refunded_hdemo_sk, cr_warehouse_sk
    ),
    web_returns_agg AS (
        SELECT
            wr_item_sk,
            wr_refunded_cdemo_sk,
            wr_refunded_hdemo_sk,
            SUM(wr_return_amt) AS total_web_return_amt,
            SUM(wr_net_loss) AS total_web_return_loss
        FROM web_returns
        WHERE wr_return_quantity > 0
          AND wr_return_amt > 0
        GROUP BY wr_item_sk, wr_refunded_cdemo_sk, wr_refunded_hdemo_sk
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    w.w_warehouse_name,
    inv.total_qty_on_hand,
    ss.total_sales,
    ss.total_profit,
    cr.total_return_amount,
    cr.total_return_loss,
    wr.total_web_return_amt,
    (ss.total_profit - COALESCE(cr.total_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0)) AS net_profit_after_returns,
    ROW_NUMBER() OVER (
        PARTITION BY ib.ib_income_band_sk
        ORDER BY (ss.total_profit - COALESCE(cr.total_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0)) DESC
    ) AS profit_rank_by_income
FROM store_sales_agg ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN inventory_agg inv
    ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns_agg cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns_agg wr
    ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_current_price > 20
  AND i.i_brand = 'Brand#12'
  AND hd.hd_buy_potential = '1001-5000'
  AND ib.ib_lower_bound >= 30000
  AND ss.total_sales > 1000
  AND cr.total_return_amount IS NOT NULL
ORDER BY net_profit_after_returns DESC
LIMIT 100

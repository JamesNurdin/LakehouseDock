WITH base AS (
    SELECT
        cp.cp_catalog_page_id,
        d.d_date,
        d.d_year,
        d.d_quarter_name,
        inv.inv_quantity_on_hand,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        ws.ws_ext_sales_price,
        ws.ws_web_page_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date DESC) AS rn,
        CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_tier
    FROM catalog_page cp
    JOIN date_dim d
      ON cp.cp_start_date_sk = d.d_date_sk
    JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
    JOIN item i
      ON inv.inv_item_sk = i.i_item_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_item_sk = i.i_item_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 1998
      AND d.d_quarter_name IN ('1903Q4', '1904Q1')
      AND i.i_current_price BETWEEN 100 AND 500
      AND cd.cd_gender = 'F'
      AND hd.hd_vehicle_count > 1
      AND ib.ib_upper_bound >= 150000
      AND sr.sr_return_quantity > 1
      AND EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_customer_sk = c.c_customer_sk
            AND sr2.sr_return_amt > 0
      )
)
SELECT
    cp_catalog_page_id,
    d_date,
    c_customer_id,
    c_first_name,
    c_last_name,
    i_item_id,
    i_product_name,
    i_current_price,
    sr_return_quantity,
    sr_return_amt,
    ws_ext_sales_price,
    sales_tier,
    rn
FROM base
ORDER BY rn
LIMIT 100

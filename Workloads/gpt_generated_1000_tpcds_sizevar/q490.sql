WITH cs_agg AS (
      SELECT
        cs_item_sk,
        cs_promo_sk,
        cs_warehouse_sk,
        cs_ship_mode_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        SUM(cs_ext_sales_price) AS cs_sales,
        SUM(cs_net_profit)      AS cs_profit
      FROM catalog_sales
      GROUP BY cs_item_sk, cs_promo_sk, cs_warehouse_sk, cs_ship_mode_sk, cs_bill_cdemo_sk, cs_bill_hdemo_sk
    ),
    ss_agg AS (
      SELECT
        ss_item_sk,
        ss_promo_sk,
        ss_store_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        SUM(ss_ext_sales_price) AS ss_sales,
        SUM(ss_net_profit)      AS ss_profit
      FROM store_sales
      GROUP BY ss_item_sk, ss_promo_sk, ss_store_sk, ss_cdemo_sk, ss_hdemo_sk
    ),
    joined AS (
      SELECT
        i1.i_brand,
        i2.i_category,
        s.s_state,
        w.w_country,
        cs_agg.cs_sales,
        ss_agg.ss_sales,
        cs_agg.cs_profit,
        ss_agg.ss_profit,
        LAG(cs_agg.cs_profit) OVER (PARTITION BY i1.i_brand ORDER BY cs_agg.cs_sales DESC) AS lag_cs_profit,
        p1.p_discount_active,
        p2.p_discount_active AS ss_promo_active
      FROM cs_agg
      FULL OUTER JOIN ss_agg
        ON cs_agg.cs_item_sk = ss_agg.ss_item_sk
       AND cs_agg.cs_promo_sk = ss_agg.ss_promo_sk
      JOIN item i1
        ON cs_agg.cs_item_sk = i1.i_item_sk
      JOIN item i2
        ON ss_agg.ss_item_sk = i2.i_item_sk
      JOIN promotion p1
        ON cs_agg.cs_promo_sk = p1.p_promo_sk
      JOIN promotion p2
        ON ss_agg.ss_promo_sk = p2.p_promo_sk
      JOIN warehouse w
        ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
      JOIN ship_mode sm
        ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN customer_demographics cd_bill
        ON cs_agg.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
      JOIN household_demographics hd_bill
        ON cs_agg.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
      JOIN store s
        ON ss_agg.ss_store_sk = s.s_store_sk
      JOIN customer_demographics cd_ship
        ON ss_agg.ss_cdemo_sk = cd_ship.cd_demo_sk
      JOIN household_demographics hd_ship
        ON ss_agg.ss_hdemo_sk = hd_ship.hd_demo_sk
      WHERE cs_agg.cs_profit > (
        SELECT AVG(cs_net_profit) FROM catalog_sales
      )
    )
SELECT
  i_brand,
  i_category,
  s_state,
  w_country,
  SUM(cs_sales) AS total_cs_sales,
  SUM(ss_sales) AS total_ss_sales,
  SUM(cs_profit) AS total_cs_profit,
  SUM(ss_profit) AS total_ss_profit,
  MAX(lag_cs_profit) AS lag_cs_profit,
  p_discount_active,
  ss_promo_active
FROM joined
GROUP BY CUBE (i_brand, i_category, s_state, w_country, p_discount_active, ss_promo_active)
HAVING SUM(cs_sales) > 100000
ORDER BY total_cs_sales DESC
LIMIT 100

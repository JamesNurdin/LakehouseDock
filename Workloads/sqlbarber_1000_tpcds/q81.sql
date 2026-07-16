SELECT i.i_category, COUNT(*) AS promo_count
FROM promotion p
JOIN item i ON p.p_item_sk = i.i_item_sk
WHERE i.i_category = 'Jewelry                                           '
GROUP BY i.i_category
